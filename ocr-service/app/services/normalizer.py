import re
import unicodedata

from app.core.config import settings


_CHAR_SUBSTITUTIONS: dict[str, str] = {
    
    "l":  "\u0e25",   
    "I":  "\u0e40",   
    "0":  "\u0e2d",   
    "O":  "\u0e2d",   
    "o":  "\u0e2d",   
    "v":  "\u0e27",   
    "u":  "\u0e27",   
    "n":  "\u0e19",   
    "m":  "\u0e21",   
    "a":  "\u0e32",   
    "i":  "\u0e34",   
    
    "\u0e01\u0e32": "\u0e01\u0e32",  
    
    
}


_THAI_CHAR_RE   = re.compile(r"[\u0e00-\u0e7f]")
_NON_THAI_RE    = re.compile(r"[^\u0e00-\u0e7f\s]")

_LEADING_DIACRITIC_RE = re.compile(r"^[\u0e34-\u0e3a\u0e47-\u0e4e]+")

_WHITESPACE_RE  = re.compile(r"\s+")
_DIGIT_RE       = re.compile(r"\d+")
_PUNCT_RE = re.compile(r"[!\"#$%&\'()*+,\-./:;<=>?@\[\\\]^_`{|}~]")

_TITLE_NORMALIZATIONS: dict[str, str] = {
    
    "นาย":   "นาย",
    "นาง":   "นาง",
    "น.ส.":  "น.ส.",
    "น,ส,":  "น.ส.",
    "นส":    "น.ส.",
    "น.ส":   "น.ส.",
    "นส.":   "น.ส.",
    "เด็กชาย": "เด็กชาย",
    "เด็กหญิง": "เด็กหญิง",
    "ดร.":   "ดร.",
    "ดร":    "ดร.",
    "พ.ต.":  "พ.ต.",
    "ร.ต.":  "ร.ต.",
}

_TITLE_RE = re.compile(
    r"^(" + "|".join(re.escape(k) for k in _TITLE_NORMALIZATIONS) + r")\s*"
)


def _apply_char_substitutions(text: str) -> str:
    """Replace known Latin-lookalike characters with their Thai equivalents."""
    return "".join(_CHAR_SUBSTITUTIONS.get(ch, ch) for ch in text)


def _remove_noise(text: str) -> str:
    """Strip digits and punctuation that shouldn't appear in a Thai name."""
    text = _DIGIT_RE.sub("", text)
    text = _PUNCT_RE.sub("", text)
    return text


def _normalize_title(text: str) -> str:
    """Normalise a mangled title prefix to its canonical form."""
    m = _TITLE_RE.match(text)
    if m:
        raw_title = m.group(1)
        canonical = _TITLE_NORMALIZATIONS.get(raw_title, raw_title)
        rest = text[m.end():]
        return canonical + " " + rest if rest else canonical
    return text


def _strip_leading_diacritics(text: str) -> str:
    """
    Remove leading vowel diacritics that have no base consonant.
    These are artefacts of EasyOCR mis-segmenting the image.
    """
    return _LEADING_DIACRITIC_RE.sub("", text)


def _collapse_whitespace(text: str) -> str:
    return _WHITESPACE_RE.sub(" ", text).strip()


def normalize_thai_name(raw: str) -> str:
    """
    Full normalization pipeline for a Thai name string from OCR.

    Steps (order matters):
      1. Unicode NFC normalisation (combine decomposed characters)
      2. Character-level substitution (Latin → Thai lookalikes)
      3. Noise removal (digits, punctuation)
      4. Title prefix normalisation
      5. Strip leading diacritics per token
      6. Collapse whitespace
    """
    if not raw:
        return ""

    
    text = unicodedata.normalize("NFC", raw)

    
    text = _apply_char_substitutions(text)

    
    text = _remove_noise(text)

    
    text = _normalize_title(text)

    
    tokens = text.split()
    tokens = [_strip_leading_diacritics(t) for t in tokens]
    tokens = [t for t in tokens if t]  

    
    text = _collapse_whitespace(" ".join(tokens))

    return text


def normalize_name_from_ocr_items(items: list[dict]) -> str:
    """
    Join all OCR result texts and normalize as a single name string.
    Filters out items below settings.MIN_CONFIDENCE_THRESHOLD before joining.
    """
    parts = [
        item["text"] for item in items
        if item.get("confidence", 0) >= settings.MIN_CONFIDENCE_THRESHOLD
    ]
    raw = " ".join(parts)
    return normalize_thai_name(raw)
