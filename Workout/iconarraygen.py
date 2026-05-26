Python 3.10.0 (v3.10.0:b494f5935c, Oct  4 2021, 14:59:19) [Clang 12.0.5 (clang-1205.0.22.11)] on darwin
Type "help", "copyright", "credits" or "license()" for more information.
from pathlib import Path

# Change this to wherever your PNG icons are stored
ICON_FOLDER = Path("./FoodIcons")

# Change this to wherever you want the Swift file generated
OUTPUT_FILE = Path("./FoodIconCatalog.swift")


def make_display_name(image_name: str) -> str:
    """
    Converts:
    protein_powder -> Protein Powder
    sweet_potato -> Sweet Potato
    apple -> Apple
    """
    return image_name.replace("_", " ").title()


def main():
    if not ICON_FOLDER.exists():
        raise FileNotFoundError(f"Icon folder does not exist: {ICON_FOLDER}")

    png_files = sorted(ICON_FOLDER.glob("*.png"))

    if not png_files:
        raise FileNotFoundError(f"No PNG files found in: {ICON_FOLDER}")

    icon_entries = []

    for file in png_files:
        image_name = file.stem
        display_name = make_display_name(image_name)

        icon_entries.append(
            f'        FoodIconOption(displayName: "{display_name}", imageName: "{image_name}")'
        )

    swift_content = f"""import Foundation

struct FoodIconOption {{
    let displayName: String
    let imageName: String
}}

enum FoodIconCatalog {{

    static let all: [FoodIconOption] = [
{",\\n".join(icon_entries)}
    ]
}}
"""

    OUTPUT_FILE.write_text(swift_content, encoding="utf-8")

    print(f"Generated {OUTPUT_FILE}")
    print(f"Found {len(png_files)} icons")


if __name__ == "__main__":
    main()