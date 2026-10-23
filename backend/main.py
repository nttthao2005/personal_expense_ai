
import os
from pathlib import Path
import logging

from google.genai import errors
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi import HTTPException
from google import genai
from schemas import ExpenseAnalysisRequest
# Luôn tìm .env bên cạnh file main.py, không phụ thuộc thư mục chạy lệnh.
BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "").strip()
gemini_client = (
    genai.Client(api_key=GEMINI_API_KEY)
    if GEMINI_API_KEY
    else None
)
app = FastAPI(
    title="Personal Expense AI API",
    description="Backend AI cho ứng dụng personal_expense_ai",
    version="1.0.0",
)


@app.get("/")
def root():
    return {
        "message": "Personal Expense AI Backend is running",
        "status": "ok",
    }


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "gemini_configured": bool(GEMINI_API_KEY),
    }


@app.post("/analyze")
def analyze_expenses(request: ExpenseAnalysisRequest):
    if gemini_client is None:
        raise HTTPException(
            status_code=503,
            detail="Gemini API chưa được cấu hình.",
        )

    categories_text = "\n".join(
        f"- {item.category}: {item.amount:,.0f} VND"
        for item in request.categories
    ) or "Chưa có dữ liệu phân loại chi tiêu."

    prompt = f"""
Bạn là trợ lý phân tích tài chính cá nhân.
Hãy phân tích dữ liệu thu chi sau bằng tiếng Việt,
dễ hiểu, thực tế và không phán xét người dùng.

Kỳ thống kê: {request.period}
Tổng thu nhập: {request.total_income:,.0f} VND
Tổng chi tiêu: {request.total_expense:,.0f} VND
Số dư: {request.balance:,.0f} VND

Chi tiêu theo danh mục:
{categories_text}

Hãy trình bày:
1. Tổng quan tình hình tài chính.
2. Danh mục chi tiêu đáng chú ý.
3. Hai hoặc ba gợi ý tiết kiệm thực tế.
4. Một lưu ý nếu dữ liệu chưa đủ để kết luận.

Chỉ dựa trên dữ liệu được cung cấp.
Không tự bịa thêm giao dịch hoặc số liệu.
"""

    try:
        response = gemini_client.interactions.create(
        model="gemini-3.5-flash-lite",
        input=prompt,
    )

        analysis = (response.output_text or "").strip()

        if not analysis:
            raise HTTPException(
                status_code=502,
                detail="Gemini không trả về nội dung phân tích.",
            )

        return {
            "status": "success",
            "period": request.period,
            "analysis": analysis,
        }

    except HTTPException:
        raise

    except errors.APIError as e:
        logging.error(
            "Gemini API error: code=%s, message=%s",
            e.code,
            e.message,
        )
        raise HTTPException(
            status_code=502,
            detail="Gemini API gặp lỗi. Hãy kiểm tra log backend.",
        ) from e

    except Exception as e:
        logging.exception("Unexpected error while calling Gemini")
        raise HTTPException(
            status_code=502,
            detail=f"Lỗi Gemini: {type(e).__name__}: {str(e)[:500]}",
        ) from e
