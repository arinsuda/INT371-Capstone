import re


def extract_thai_id(items: list[dict]) -> str | None:
    for t in items:
        clean = re.sub(r"\D", "", t["text"])
        if len(clean) == 13:
            return clean
    return None


def validate_thai_id(id_number: str) -> bool:
    if not id_number or len(id_number) != 13:
        return False
    total = sum(int(id_number[i]) * (13 - i) for i in range(12))
    check = (11 - (total % 11)) % 10
    return check == int(id_number[-1])