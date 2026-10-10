from pathlib import Path
from PIL import Image
from typing import Dict

downloads = Path.home() / "Downloads"
out = Path(__file__).resolve().parents[1] / "apps" / "wantok_app" / "assets" / "images" / "reference"
out.mkdir(parents=True, exist_ok=True)

def extract(filename: str, boxes: Dict[str, tuple]):
    image = Image.open(downloads / filename).convert("RGB")
    scale_x = image.width / 928
    scale_y = image.height / 1648
    print(f"SOURCE {filename} {image.width}x{image.height}")
    for name, (x1, y1, x2, y2) in boxes.items():
        cropped = image.crop(tuple(map(round, (x1*scale_x,y1*scale_y,x2*scale_x,y2*scale_y))))
        suffix = "png" if name.endswith("_icon") else "jpg"
        target = out / f"{name}.{suffix}"
        if suffix == "png":
            cropped.save(target, optimize=True)
        else:
            cropped.save(target, quality=89, optimize=True)
        print(f"{target.name}: {cropped.width}x{cropped.height}")

extract("ChatGPT Image Oct 10, 2026, 09_13_32 PM.png", {
    "public_hero_photo": (549, 426, 895, 700),
    "public_emergency_icon": (46, 940, 158, 1043),
    "public_health_icon": (491, 939, 603, 1044),
    "public_government_icon": (46, 1242, 160, 1347),
    "public_community_icon": (489, 1242, 601, 1348),
    "public_emergency_photo": (41, 1056, 445, 1208),
    "public_health_photo": (483, 1057, 886, 1209),
    "public_government_photo": (41, 1365, 445, 1517),
    "public_community_photo": (482, 1365, 887, 1517),
})
extract("ChatGPT Image Oct 10, 2026, 09_13_25 PM.png", {
    "services_taxi_icon": (45, 435, 158, 537),
    "services_hire_icon": (490, 436, 600, 536),
    "services_food_icon": (47, 741, 159, 840),
    "services_groceries_icon": (489, 741, 600, 841),
    "services_delivery_icon": (46, 1031, 158, 1134),
    "services_travel_icon": (491, 1030, 602, 1134),
    "services_specialists_icon": (47, 1308, 158, 1408),
    "services_public_icon": (489, 1307, 601, 1410),
    "services_taxi_photo": (40, 547, 445, 700),
    "services_hire_photo": (483, 545, 888, 700),
    "services_food_photo": (42, 849, 445, 993),
    "services_groceries_photo": (483, 850, 888, 992),
    "services_delivery_photo": (42, 1138, 445, 1270),
    "services_travel_photo": (483, 1139, 888, 1270),
    "services_specialists_photo": (42, 1412, 445, 1530),
    "services_public_photo": (482, 1412, 888, 1530),
})
