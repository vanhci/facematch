import os, base64, json, uuid, datetime, shutil
from pathlib import Path
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import uvicorn
import requests

# Upload directory for persisted images
UPLOAD_DIR = Path(__file__).parent / "uploads"
UPLOAD_DIR.mkdir(exist_ok=True)

# Load .env file if exists
env_path = Path(__file__).parent.parent / ".env"
if env_path.exists():
    for line in env_path.read_text().splitlines():
        if "=" in line and not line.startswith("#"):
            k, v = line.split("=", 1)
            os.environ.setdefault(k.strip(), v.strip())

app = FastAPI(title="FaceMatch API", version="2.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

# Serve uploaded images
app.mount("/uploads", StaticFiles(directory=str(UPLOAD_DIR)), name="uploads")

# Serve static HTML for auth confirmation
from fastapi.responses import HTMLResponse


@app.get("/", response_class=HTMLResponse)
@app.get("/auth/confirm", response_class=HTMLResponse)
async def auth_confirm(code: str = "", type: str = ""):
    """Handle email confirmation redirect from Supabase Auth"""
    if not code:
        return HTMLResponse("""
<!DOCTYPE html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>颜摹 - 邮箱确认</title>
<style>
body { font-family: -apple-system, sans-serif; background: #fcf5f5; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; padding: 20px; text-align: center; }
.card { background: white; border-radius: 24px; padding: 40px; box-shadow: 0 4px 24px rgba(0,0,0,0.08); max-width: 400px; }
.icon { font-size: 48px; margin-bottom: 16px; }
h1 { font-size: 22px; color: #333; margin: 0 0 8px; }
p { font-size: 14px; color: #888; line-height: 1.6; margin: 0; }
.btn { display: inline-block; margin-top: 20px; padding: 12px 32px; background: #f0708d; color: white; border-radius: 16px; text-decoration: none; font-weight: 600; border: none; font-size: 15px; cursor: pointer; }
.hidden { display: none; }
</style></head><body>
<div class="card">
<div class="icon">📧</div>
<h1>验证邮箱</h1>
<p>请查收邮件中的确认链接，点击后即可完成注册。</p>
<p style="margin-top:12px;font-size:12px;color:#bbb">没收到？请检查垃圾邮件。</p>
</div></body></html>
""")

    # Verify the code via Supabase Auth API
    try:
        h = supabase_headers()
        verify_url = f"{SUPABASE_URL}/auth/v1/verify"
        payload = {"type": type or "signup", "token": code, "redirect_to": ""}
        r = requests.post(verify_url, headers={"apikey": SUPABASE_KEY, "Content-Type": "application/json"}, json=payload, timeout=10)
        success = r.status_code in (200, 201)
    except Exception:
        success = False

    if success:
        return HTMLResponse(f"""
<!DOCTYPE html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>颜摹 - 邮箱确认成功</title>
<style>
body {{ font-family: -apple-system, sans-serif; background: #fcf5f5; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; padding: 20px; text-align: center; }}
.card {{ background: white; border-radius: 24px; padding: 40px; box-shadow: 0 4px 24px rgba(0,0,0,0.08); max-width: 400px; }}
.icon {{ font-size: 48px; margin-bottom: 16px; }}
h1 {{ font-size: 22px; color: #333; margin: 0 0 8px; }}
p {{ font-size: 14px; color: #888; line-height: 1.6; margin: 0; }}
.btn {{ display: inline-block; margin-top: 20px; padding: 12px 32px; background: #f0708d; color: white; border-radius: 16px; text-decoration: none; font-weight: 600; }}
</style></head><body>
<div class="card">
<div class="icon">✅</div>
<h1>邮箱确认成功</h1>
<p>你的邮箱已通过验证，注册已完成！</p>
<p style="margin-top:8px;font-size:13px;color:#aaa">现在可以关闭此页面，打开 App 登录即可。</p>
</div></body></html>""")
    else:
        return HTMLResponse(f"""
<!DOCTYPE html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>颜摹 - 确认失败</title>
<style>
body {{ font-family: -apple-system, sans-serif; background: #fcf5f5; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; padding: 20px; text-align: center; }}
.card {{ background: white; border-radius: 24px; padding: 40px; box-shadow: 0 4px 24px rgba(0,0,0,0.08); max-width: 400px; }}
.icon {{ font-size: 48px; margin-bottom: 16px; }}
h1 {{ font-size: 22px; color: #333; margin: 0 0 8px; }}
p {{ font-size: 14px; color: #888; line-height: 1.6; margin: 0; }}
</style></head><body>
<div class="card">
<div class="icon">❌</div>
<h1>确认链接无效或已过期</h1>
<p>请重新注册，确认链接有效期为 1 小时。</p>
</div></body></html>""")


@app.get("/api/v2/config")
async def get_config():
    """Return client-facing Supabase config"""
    return {
        "supabase_url": "https://woqlrmmlhluaeaizrizg.supabase.co",
        "supabase_anon_key": "*** ...BxPQ"
    }

# DashScope
KEY = "sk-ws-H.RYLMMME.gTxT.MEUCIQCaj-tKLaEqh3kvvlDDKWC8nlYDfM3Ej-vi4UYJePy0EQIgJzgfIoxXYvDZedkNOIFYpAzcBBQn0AZ7tfqO4xo1xkQ"
BASE = "https://dashscope.aliyuncs.com"

# Supabase
SUPABASE_URL = "https://woqlrmmlhluaeaizrizg.supabase.co"
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_KEY", "")


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
    """查询用户用量和剩余次数，自动创建用户记录"""
    url = f"{SUPABASE_URL}/rest/v1/facematch_users"
    h = supabase_headers()
    r = requests.get(url, headers=h,
                     params={"id": f"eq.{user_id}", "select": "tier,daily_usage,daily_usage_date,bonus_credits,premium_expires_at"},
                     timeout=10)
    users = r.json()
    if not users:
        # Auto-create user record for Auth users
        limit = int(os.environ.get("DAILY_LIMIT", "999"))
        today = datetime.date.today().isoformat()
        payload = {"id": user_id, "nickname": "用户", "created_at": datetime.datetime.utcnow().isoformat(),
                   "last_login": datetime.datetime.utcnow().isoformat(),
                   "tier": "free", "daily_usage": 0, "daily_usage_date": today}
        try:
            r2 = requests.post(url, headers=h, json=payload, timeout=10)
            if r2.status_code in (200, 201):
                return {"tier": "free", "daily_usage": 0, "daily_limit": limit,
                        "bonus_credits": 0, "remaining": limit, "is_premium": False}
        except:
            pass
        raise HTTPException(404, "用户不存在")
    user = users[0]
    today = datetime.date.today().isoformat()
    is_premium = user["tier"] == "premium" and (user.get("premium_expires_at") is None or
                                                 user["premium_expires_at"] >= today)
    daily = 0 if user.get("daily_usage_date") != today else user["daily_usage"]
    limit = 999 if is_premium else int(os.environ.get("DAILY_LIMIT", "999"))
    remaining = max(0, limit - daily) + (user["bonus_credits"] or 0)
    return {"tier": user["tier"], "daily_usage": daily, "daily_limit": limit,
            "bonus_credits": user["bonus_credits"] or 0, "remaining": remaining, "is_premium": is_premium}


# ─── 仿妆模块 ───────────────────────────────

@app.post("/api/v1/analyze")
async def analyze(reference_image: UploadFile = File(...), user_id: str = Form(default="")):
    data = await reference_image.read()
    # Resize for faster analysis
    import cv2, numpy as np
    arr = cv2.imdecode(np.frombuffer(data, np.uint8), cv2.IMREAD_COLOR)
    if arr is not None and max(arr.shape[:2]) > 1024:
        scale = 1024 / max(arr.shape[:2])
        arr = cv2.resize(arr, (int(arr.shape[1]*scale), int(arr.shape[0]*scale)), interpolation=cv2.INTER_AREA)
        _, enc = cv2.imencode('.jpg', arr, [cv2.IMWRITE_JPEG_QUALITY, 85])
        data = enc.tobytes()
    payload = {
        "model": "qwen3.7-plus",
        "messages": [{"role": "user", "content": [
            {"type": "image_url", "image_url": {"url": img_b64(data)}},
            {"type": "text", "text": "分析这张照片的妆容和面部结构。用JSON格式输出，key为以下中文字段名，每个value是一段连贯的中文描述（不要拆分子字段）：面型（判断脸型并描述轮廓）、底妆、眼妆、眉妆、腮红、唇妆、修容、发型、配饰。"}
        ]}],
        "max_tokens": 1200
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
async def transfer(selfie_image: UploadFile = File(...), analysis: str = Form(...), user_id: str = Form(default=""), reference_image: UploadFile = File(default=None)):
    data = await selfie_image.read()
    from dashscope import MultiModalConversation
    img_b64_local = base64.b64encode(data).decode()
    data_uri = f"data:image/jpeg;base64,{img_b64_local}"

    ref_data = None
    if reference_image:
        ref_data = await reference_image.read()

    try:
        analysis_json = json.loads(analysis)
        makeup_desc = "；".join([
            f"{k}：{analysis_json.get(k, '')[:300]}"
            for k in ["底妆", "眼妆", "眉妆", "腮红", "唇妆", "修容"]
            if analysis_json.get(k)
        ])
        hair_desc = analysis_json.get("发型", "")[:200]
        accessory_desc = analysis_json.get("配饰", "")[:200]
        face_structure = analysis_json.get("面型", "")[:200]
    except (json.JSONDecodeError, TypeError):
        makeup_desc = hair_desc = accessory_desc = face_structure = ""

    prompt_parts = ["Apply the reference makeup to this person naturally."]
    if face_structure:
        prompt_parts.append(f"Preserve this face structure exactly: {face_structure}.")
    else:
        prompt_parts.append("Keep the original skin color, facial features, expression, and background unchanged.")
    prompt_parts.append("Only the makeup style should change — subtle and natural.")
    if makeup_desc:
        prompt_parts.append(f"Makeup reference: {makeup_desc}")
    if hair_desc:
        prompt_parts.append(f"Hairstyle: {hair_desc[:80]}")
    if accessory_desc:
        prompt_parts.append(f"Accessories: {accessory_desc[:80]}")
    if not hair_desc and not accessory_desc:
        prompt_parts.append("Keep clothing, background, and identity completely unchanged.")
    else:
        prompt_parts.append("Keep clothing, background, and identity completely unchanged.")
    prompt_text = "\n".join(prompt_parts)
    image_model = os.environ.get("IMAGE_MODEL", "dashscope")
    print(f"[transfer] Using model: {image_model}")

    if image_model == "minimax":
        result = await _transfer_minimax(data, prompt_text)
    elif image_model == "qwen-edit":
        result = await _transfer_qwen_edit(data, prompt_text)
    elif image_model == "gpt-image-2":
        result = await _transfer_gpt_image2(data, prompt_text, makeup_desc, hair_desc, accessory_desc)
    else:
        result = await _transfer_dashscope(data_uri, prompt_text)

    # Record usage
    if user_id:
        _record_usage(user_id, "transfer")

    return result


async def _transfer_dashscope(data_uri: str, prompt_text: str):
    """Use DashScope wan2.7-image-pro for transfer"""
    from dashscope import MultiModalConversation
    messages = [{"role": "user", "content": [{"image": data_uri}, {"text": prompt_text}]}]
    resp = MultiModalConversation.call(
        model="wan2.7-image-pro", messages=messages, api_key=KEY,
        parameters={"size": "1328*1328", "n": 1, "watermark": False, "denoise_strength": 0.1}
    )
    result = resp if isinstance(resp, dict) else resp.__dict__
    if result.get("status_code") != 200:
        raise HTTPException(500, f"生成失败: {result.get('message', 'unknown')}")
    img_url = result["output"]["choices"][0]["message"]["content"][0]["image"]
    return {"result_url": img_url}


async def _transfer_minimax(original_data: bytes, prompt_text: str):
    """Use MiniMax image-01 for transfer with subject reference"""
    import base64
    mm_key = os.environ.get("MINIMAX_API_KEY", "")
    mm_url = os.environ.get("MINIMAX_API_URL", "https://api.minimaxi.com/v1/image_generation")
    img_b64_str = base64.b64encode(original_data).decode()
    payload = {
        "model": "image-01",
        "prompt": prompt_text,
        "subject_reference": [{
            "type": "character",
            "image_file": f"data:image/jpeg;base64,{img_b64_str}"
        }],
        "n": 1,
    }
    headers = {"Authorization": f"Bearer {mm_key}", "Content-Type": "application/json"}
    resp = requests.post(mm_url, json=payload, headers=headers, timeout=120)
    if resp.status_code != 200:
        raise HTTPException(500, f"MiniMax生成失败: {resp.text[:200]}")
    result = resp.json()
    # Check base_resp
    base = result.get("base_resp", {})
    if base.get("status_code", -1) != 0:
        raise HTTPException(500, f"MiniMax错误: {base.get('status_msg', 'unknown')}")
    img_urls = result.get("data", {}).get("image_urls", [])
    if not img_urls:
        raise HTTPException(500, f"MiniMax返回无图片")
    return {"result_url": img_urls[0]}


@app.get("/privacy", response_class=HTMLResponse)
async def privacy_policy():
    return """<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>颜摹 - 隐私政策</title>
<style>
body{font-family:-apple-system,BlinkMacSystemFont,"PingFang SC","Helvetica Neue",sans-serif;background:#fcf5f5;margin:0;padding:20px;color:#333;line-height:1.8}
.card{max-width:720px;margin:20px auto;background:#fff;border-radius:20px;padding:32px;box-shadow:0 4px 24px rgba(0,0,0,0.06)}
h1{font-size:24px;color:#2d2d2d;margin:0 0 8px}
h2{font-size:18px;color:#2d2d2d;margin:24px 0 8px}
p{font-size:14px;color:#666;margin:0 0 12px}
.footer{font-size:12px;color:#aaa;text-align:center;margin-top:32px}
</style>
</head>
<body>
<div class="card">
<h1>隐私政策</h1>
<p>最后更新：2026年7月2日</p>

<h2>1. 信息收集</h2>
<p>颜摹（以下简称"本应用"）仅收集您主动上传的照片数据用于妆容分析和仿妆生成。我们不会收集您的姓名、手机号、位置等个人信息。</p>

<h2>2. 照片数据</h2>
<p>您上传的照片仅用于实时妆容分析和仿妆效果生成。处理完成后，照片数据会在服务器上保留不超过24小时后自动删除。您可以随时在应用中删除历史记录。</p>

<h2>3. 第三方服务</h2>
<p>本应用使用阿里云DashScope API进行图像分析处理。您的照片数据会在处理过程中传输至阿里云服务器，处理完成后不会存储在第三方服务器上。</p>

<h2>4. 数据安全</h2>
<p>我们采用行业标准的安全措施保护您的数据传输和存储安全。所有网络通信均使用加密传输（HTTPS）。</p>

<h2>5. 联系我们</h2>
<p>如有任何关于隐私政策的疑问，请联系我们：vanhci@live.cn</p>

<div class="footer">© 2026 颜摹. All rights reserved.</div>
</div>
</body>
</html>"""


async def _transfer_qwen_edit(original_data: bytes, prompt_text: str):
    """Use qwen-image-2.0-pro for makeup transfer"""
    import base64, cv2, numpy as np
    # Resize image to max 1024px for faster processing
    img_arr = cv2.imdecode(np.frombuffer(original_data, np.uint8), cv2.IMREAD_COLOR)
    if img_arr is not None:
        h, w = img_arr.shape[:2]
        if max(h, w) > 1024:
            scale = 1024 / max(h, w)
            new_w, new_h = int(w * scale), int(h * scale)
            img_arr = cv2.resize(img_arr, (new_w, new_h), interpolation=cv2.INTER_AREA)
            _, encoded = cv2.imencode('.jpg', img_arr, [cv2.IMWRITE_JPEG_QUALITY, 90])
            original_data = encoded.tobytes()
            print(f"[resize] {w}x{h} -> {new_w}x{new_h}")
    img_b64 = base64.b64encode(original_data).decode()
    mm_url = "https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation"
    payload = {
        "model": "qwen-image-2.0-pro-2026-06-22",
        "input": {
            "messages": [{
                "role": "user",
                "content": [
                    {"image": f"data:image/jpeg;base64,{img_b64}"},
                    {"text": prompt_text}
                ]
            }]
        },
        "parameters": {"result_format": "message"}
    }
    headers = {"Authorization": f"Bearer {KEY}", "Content-Type": "application/json"}
    resp = requests.post(mm_url, json=payload, headers=headers, timeout=120)
    if resp.status_code != 200:
        err_msg = resp.text[:200]
        try:
            err_detail = resp.json()
            err_msg = str(err_detail)[:200]
        except:
            pass
        raise HTTPException(500, f"生成失败: {err_msg}")
    result = resp.json()
    images = result.get("output", {}).get("choices", [{}])[0].get("message", {}).get("content", [])
    for item in images:
        if "image" in item:
            oss_url = item["image"]
            try:
                img_resp = requests.get(oss_url, timeout=10)
                if img_resp.status_code == 200:
                    import uuid, os
                    os.makedirs("uploads", exist_ok=True)
                    filename = f"{uuid.uuid4()}.png"
                    path = f"uploads/{filename}"
                    with open(path, "wb") as f:
                        f.write(img_resp.content)
                    local_url = f"{os.environ.get('SITE_URL', 'https://facematch.vanhci.top')}/{path}"
                    return {"result_image_base64": "", "result_url": local_url}
            except:
                pass
            return {"result_url": oss_url}
    raise HTTPException(500, "Qwen-Edit返回无图片")


async def _transfer_gpt_image2(original_data: bytes, prompt_text: str, makeup_desc: str = "", hair_desc: str = "", accessory_desc: str = ""):
    """Use OpenAI gpt-image-2 via r7z.net relay for makeup transfer"""
    import subprocess, json, base64, tempfile, os, uuid
    api_key = os.environ.get("R7Z_API_KEY", "")
    base_url = os.environ.get("R7Z_BASE_URL", "https://hk1.r7z.net/v1")
    img_b64 = base64.b64encode(original_data).decode()

    # gpt-image-2 专用提示词
    gpt_prompt = "Edit this image: apply subtle natural makeup."
    gpt_prompt += " Keep the face EXACTLY the same — same eyes, nose, mouth shape, expression, head angle."
    gpt_prompt += " Keep background, clothing, hair, lighting completely unchanged."
    if makeup_desc:
        gpt_prompt += f" Add makeup: {makeup_desc}."
    if hair_desc:
        gpt_prompt += f" Adjust hair: {hair_desc}."
    if accessory_desc:
        gpt_prompt += f" Adjust accessories: {accessory_desc}."
    if not makeup_desc and not hair_desc and not accessory_desc:
        gpt_prompt += " Very light natural everyday makeup only."

    payload = {
        "model": "gpt-image-2",
        "prompt": gpt_prompt,
        "image": [f"data:image/jpeg;base64,{img_b64}"],
        "size": "1024x1024",
        "quality": "high",
        "n": 1,
        "response_format": "b64_json",
    }

    cmd = [
        "curl", "-s", "--insecure", "--max-time", "180",
        "-H", f"Authorization: Bearer {api_key}",
        "-H", "Content-Type: application/json",
        "-d", json.dumps(payload),
        f"{base_url.rstrip('/')}/images/generations",
    ]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=200)
        data = json.loads(result.stdout)
    except Exception as e:
        raise HTTPException(500, f"GPT-Image-2调用失败: {str(e)[:200]}")

    if "error" in data:
        raise HTTPException(500, f"GPT-Image-2错误: {data['error'].get('message', 'unknown')}")
    if "data" not in data or not data["data"]:
        raise HTTPException(500, "GPT-Image-2返回空数据")

    b64_str = data["data"][0].get("b64_json")
    if not b64_str:
        raise HTTPException(500, "GPT-Image-2无b64_json")

    img_bytes = base64.b64decode(b64_str)
    os.makedirs("uploads", exist_ok=True)
    stable_path = f"uploads/{uuid.uuid4()}.png"
    with open(stable_path, "wb") as f:
        f.write(img_bytes)
    return {"result_image_base64": base64.b64encode(img_bytes).decode(), "result_url": f"/{stable_path}"}


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
    print(f"[save_history] Supabase response: {r.status_code} {r.text[:200]}")
    if r.status_code not in (200, 201):
        raise HTTPException(500, "保存历史失败")
    return r.json()[0] if r.text and r.text != "[]" else record


@app.delete("/api/v2/history/{record_id}")
async def delete_history(record_id: str, user_id: str = Form(...)):
    url = f"{SUPABASE_URL}/rest/v1/facematch_history"
    r = requests.delete(f"{url}?id=eq.{record_id}&user_id=eq.{user_id}",
                        headers=supabase_headers(), timeout=10)
    return {"deleted": r.status_code in (200, 204)}


@app.post("/api/v2/upload")
async def upload_image(file: UploadFile = File(...)):
    """Upload an image and return its accessible URL"""
    ext = Path(file.filename or "image.jpg").suffix or ".jpg"
    filename = f"{uuid.uuid4()}{ext}"
    filepath = UPLOAD_DIR / filename
    with open(filepath, "wb") as f:
        shutil.copyfileobj(file.file, f)
    return {"url": f"/uploads/{filename}"}


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
