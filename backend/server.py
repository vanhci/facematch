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
            {"type": "text", "text": "分析这张照片的整体造型。用JSON输出以下字段，每个字段给出详细中文描述（颜色、质地、位置、风格）：底妆、眼妆、眉妆、腮红、唇妆、修容、发型、配饰。"}
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
    messages = [{"role": "user", "content": [
        {"image": data_uri},
        {"text": f"Subtle natural everyday makeup ONLY. Very light warm brown eyeshadow, thin eyeliner, soft coral blush, natural pink lip gloss. Keep the original face, features, and skin texture completely unchanged. The result should look like NO makeup was added - just a slightly fresher version of the original. DO NOT add heavy eyeshadow, dark lipstick, or dramatic makeup."}
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
