import os, base64, json
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
import uvicorn
import requests

app = FastAPI(title="FaceMatch API", version="1.0.0")
KEY = "sk-ws-H.RYLMMME.gTxT.MEUCIQCaj-tKLaEqh3kvvlDDKWC8nlYDfM3Ej-vi4UYJePy0EQIgJzgfIoxXYvDZedkNOIFYpAzcBBQn0AZ7tfqO4xo1xkQ"
BASE = "https://dashscope.aliyuncs.com"

def img_b64(data):
    return f"data:image/jpeg;base64,{base64.b64encode(data).decode()}"

@app.post("/api/v1/analyze")
async def analyze(reference_image: UploadFile = File(...)):
    data = await reference_image.read()
    payload = {
        "model": "qwen3.7-plus",
        "messages": [{"role": "user", "content": [
            {"type": "image_url", "image_url": {"url": img_b64(data)}},
            {"type": "text", "text": "分析这张照片的妆容和整体造型。用JSON格式输出，key为以下字段名，每个字段的value是一段连贯的中文描述（不要拆分成颜色/质地/位置/风格子字段，直接写一段话）：底妆、眼妆、眉妆、腮红、唇妆、修容、发型、配饰。"}
        ]}],
        "max_tokens": 800
    }
    resp = requests.post(f"{BASE}/compatible-mode/v1/chat/completions", json=payload,
        headers={"Authorization": f"Bearer {KEY}"}, timeout=60)
    if resp.status_code != 200:
        raise HTTPException(500, f"分析失败: {resp.text}")
    content = resp.json()["choices"][0]["message"]["content"]
    if not isinstance(content, str):
        content = json.dumps(content, ensure_ascii=False)
    return {"analysis": content}

@app.post("/api/v1/transfer")
async def transfer(selfie_image: UploadFile = File(...), analysis: str = Form(...)):
    data = await selfie_image.read()
    from dashscope import MultiModalConversation
    import base64
    img_b64 = base64.b64encode(data).decode()
    data_uri = f"data:image/jpeg;base64,{img_b64}"

    # Parse analysis JSON to extract makeup, hairstyle, accessories
    try:
        analysis_json = json.loads(analysis)
        makeup_desc = "；".join([
            f"{k}：{analysis_json.get(k, '')[:80]}"
            for k in ["底妆", "眼妆", "眉妆", "腮红", "唇妆", "修容"]
            if analysis_json.get(k)
        ])
        hair_desc = analysis_json.get("发型", "")
        accessory_desc = analysis_json.get("配饰", "")
    except (json.JSONDecodeError, TypeError):
        makeup_desc = ""
        hair_desc = ""
        accessory_desc = ""

    prompt_parts = ["Apply the following makeup to the person in this photo:"]
    if makeup_desc:
        prompt_parts.append(f"Makeup style: {makeup_desc}")
    if hair_desc:
        prompt_parts.append(f"Hairstyle: {hair_desc[:120]}")
    if accessory_desc:
        prompt_parts.append(f"Accessories: {accessory_desc[:120]}")
    prompt_parts.append("Keep the original face, features, skin texture and identity completely unchanged.")
    prompt_parts.append("Make the hairstyle and any accessories visible in the generated result.")
    prompt_text = "\n".join(prompt_parts)

    messages = [{"role": "user", "content": [
        {"image": data_uri},
        {"text": prompt_text}
    ]}]
    resp = MultiModalConversation.call(
        model="wan2.7-image-pro",
        messages=messages,
        api_key=KEY,
        parameters={
            "size": "1328*1328",
            "n": 1,
            "watermark": False,
            "denoise_strength": 0.3,
        }
    )
    result = resp if isinstance(resp, dict) else resp.__dict__
    if result.get("status_code") != 200:
        raise HTTPException(500, f"生成失败: {result.get('message', 'unknown')}")
    img_url = result["output"]["choices"][0]["message"]["content"][0]["image"]
    return {"result_url": img_url}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8765)
