
from pydantic import BaseModel, Field


class CategorySpending(BaseModel):
    category: str = Field(min_length=1, max_length=100)
    amount: float = Field(gt=0)


class ExpenseAnalysisRequest(BaseModel):
    period: str = Field(min_length=1, max_length=50)
    total_income: float = Field(ge=0)
    total_expense: float = Field(ge=0)
    balance: float
    categories: list[CategorySpending] = Field(default_factory=list)
