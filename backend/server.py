import os, base64, json, uuid, datetime
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import requests

app = FastAPI(title="FaceMatch API", version="2.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

# DashScope
KEY = "sk-ws-H.RYLMMME.gTxT.MEUCIQCaj-tKLaEqh3kvvlDDKWC8nlYDfM3Ej-vi4UYJePy0EQIgJzgfIoxXYvDZedkNOIFYpAzcBBQn0AZ7tfqO4xo1xkQ"
BASE = "https://dashscope.aliyuncs.com"

# Supabase
SUPABASE_URL = "https://woqlrmmlhluaeaizrizg.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndvcWxybW1saGx1YWVhaXpyaXpnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI2NTAwOTUsImV4cCI6MjA5ODIyNjA5NX0.OLkvc5RWv5EQ--nCixs61HD8jculYiGKqijYqO-BxPQ"


def supabase_headers():
    return {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal",
    }


def img_b64(data):
    return f"data:image/jpeg;base64,{base64.b64encode(data).decode()}"


# ─── 用户模块 ───────────────────────────────

@app.post("/api/v2/user/login")
async def login(phone: str = Form(...), nickname: str = Form(default="")):
    """手机号登录/注册"""
    url = f"{SUPABASE_URL}/rest/v1/facematch_users"
    h = supabase_headers()
    # Check if user exists
    r = requests.get(url, headers=h, params={"phone": f"eq.{phone}"}, timeout=10)
    users = r.json()
    if users and len(users) > 0:
        user = users[0]
        # Update last_login
        requests.patch(f"{url}?id=eq.{user['id']}", headers=h,
                       json={"last_login": datetime.datetime.utcnow().isoformat()}, timeout=10)
        # Reset daily usage if new day
        today = datetime.date.today().isoformat()
        if user.get("daily_usage_date") != today:
            requests.patch(f"{url}?id=eq.{user['id']}", headers=h,
                           json={"daily_usage": 0, "daily_usage_date": today}, timeout=10)
        return {"user_id": user["id"], "nickname": user["nickname"], "tier": user["tier"],
                "daily_usage": 0 if user.get("daily_usage_date") != today else user["daily_usage"],
                "bonus_credits": user["bonus_credits"], "is_new": False}
    # Create new user
    user_id = str(uuid.uuid4())
    today = datetime.date.today().isoformat()
    payload = {"id": user_id, "phone": phone, "nickname": nickname or f"用户{phone[-4:]}",
               "created_at": datetime.datetime.utcnow().isoformat(),
               "last_login": datetime.datetime.utcnow().isoformat(),
               "tier": "free", "daily_usage": 0, "daily_usage_date": today}
    r = requests.post(url, headers=h, json=payload, timeout=10)
    if r.status_code not in (200, 201):
        raise HTTPException(500, "注册失败")
    return {"user_id": user_id, "nickname": payload["nickname"], "tier": "free",
            "daily_usage": 0, "bonus_credits": 0, "is_new": True}


@app.get("/api/v2/user/usage/{user_id}")
async def get_usage(user_id: str):
    """查询用户用量和剩余次数"""
    url = f"{SUPABASE_URL}/rest/v1/facematch_users"
    r = requests.get(url, headers=supabase_headers(),
                     params={"id": f"eq.{user_id}", "select": "tier,daily_usage,daily_usage_date,bonus_credits,premium_expires_at"},
                     timeout=10)
    users = r.json()
    if not users:
        raise HTTPException(404, "用户不存在")
    user = users[0]
    today = datetime.date.today().isoformat()
    is_premium = user["tier"] == "premium" and (user.get("premium_expires_at") is None or
                                                 user["premium_expires_at"] >= today)
    daily = 0 if user.get("daily_usage_date") != today else user["daily_usage"]
    limit = 999 if is_premium else 3
    remaining = max(0, limit - daily) + (user["bonus_credits"] or 0)
    return {"tier": user["tier"], "daily_usage": daily, "daily_limit": limit,
            "bonus_credits": user["bonus_credits"] or 0, "remaining": remaining, "is_premium": is_premium}


# ─── 仿妆模块 ───────────────────────────────

@app.post("/api/v1/analyze")
async def analyze(reference_image: UploadFile = File(...), user_id: str = Form(default="")):
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

    # Record usage
    if user_id:
        _record_usage(user_id, "analyze")

    return {"analysis": content}


@app.post("/api/v1/transfer")
async def transfer(selfie_image: UploadFile = File(...), analysis: str = Form(...), user_id: str = Form(default="")):
    data = await selfie_image.read()
    from dashscope import MultiModalConversation
    img_b64_local = base64.b64encode(data).decode()
    data_uri = f"data:image/jpeg;base64,{img_b64_local}"

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
        makeup_desc = hair_desc = accessory_desc = ""

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

    messages = [{"role": "user", "content": [{"image": data_uri}, {"text": prompt_text}]}]
    resp = MultiModalConversation.call(
        model="wan2.7-image-pro", messages=messages, api_key=KEY,
        parameters={"size": "1328*1328", "n": 1, "watermark": False, "denoise_strength": 0.3}
    )
    result = resp if isinstance(resp, dict) else resp.__dict__
    if result.get("status_code") != 200:
        raise HTTPException(500, f"生成失败: {result.get('message', 'unknown')}")
    img_url = result["output"]["choices"][0]["message"]["content"][0]["image"]

    # Record usage
    if user_id:
        _record_usage(user_id, "transfer")

    return {"result_url": img_url}


# ─── 历史模块 ───────────────────────────────

@app.get("/api/v2/history/{user_id}")
async def get_history(user_id: str, limit: int = 50, offset: int = 0):
    url = f"{SUPABASE_URL}/rest/v1/facematch_history"
    r = requests.get(url, headers=supabase_headers(),
                     params={"user_id": f"eq.{user_id}", "order": "created_at.desc",
                             "limit": limit, "offset": offset}, timeout=10)
    return r.json()


@app.post("/api/v2/history")
async def save_history(data: dict):
    url = f"{SUPABASE_URL}/rest/v1/facematch_history"
    h = supabase_headers()
    h["Prefer"] = "return=representation"
    record = {
        "id": str(uuid.uuid4()),
        "user_id": data.get("user_id"),
        "reference_image_url": data.get("reference_image_url", ""),
        "selfie_image_url": data.get("selfie_image_url", ""),
        "result_image_url": data.get("result_image_url", ""),
        "analysis": json.dumps(data.get("analysis", {}), ensure_ascii=False),
        "status": "completed",
        "created_at": datetime.datetime.utcnow().isoformat()
    }
    r = requests.post(url, headers=h, json=record, timeout=10)
    if r.status_code not in (200, 201):
        raise HTTPException(500, "保存历史失败")
    return r.json()[0] if r.text and r.text != "[]" else record


@app.delete("/api/v2/history/{record_id}")
async def delete_history(record_id: str, user_id: str = Form(...)):
    url = f"{SUPABASE_URL}/rest/v1/facematch_history"
    r = requests.delete(f"{url}?id=eq.{record_id}&user_id=eq.{user_id}",
                        headers=supabase_headers(), timeout=10)
    return {"deleted": r.status_code in (200, 204)}


# ─── 内部 ───────────────────────────────

def _record_usage(user_id: str, action: str):
    """记录用量并更新 daily_usage"""
    try:
        h = supabase_headers()
        today = datetime.date.today().isoformat()

        # Insert usage record
        requests.post(f"{SUPABASE_URL}/rest/v1/facematch_usage", headers=h, json={
            "id": str(uuid.uuid4()), "user_id": user_id, "action": action,
            "cost_credits": 1, "created_at": datetime.datetime.utcnow().isoformat()
        }, timeout=5)

        # Increment daily usage
        user_url = f"{SUPABASE_URL}/rest/v1/facematch_users"
        r = requests.get(user_url, headers=h, params={"id": f"eq.{user_id}",
                         "select": "daily_usage,daily_usage_date"}, timeout=5)
        user = r.json()[0] if r.text and r.text != "[]" else {}
        if user.get("daily_usage_date") != today:
            requests.patch(f"{user_url}?id=eq.{user_id}", headers=h,
                           json={"daily_usage": 1, "daily_usage_date": today}, timeout=5)
        else:
            requests.patch(f"{user_url}?id=eq.{user_id}", headers=h,
                           json={"daily_usage": (user.get("daily_usage") or 0) + 1}, timeout=5)
    except Exception as e:
        print(f"Usage recording error (non-fatal): {e}")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8765)
