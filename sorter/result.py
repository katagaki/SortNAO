from playwright.sync_api import ElementHandle

from sorter.constants import (
    classname_div_result_image,
    classname_div_result_title,
    classname_div_result_content,
    prefix_creator,
    prefix_source,
    prefix_material,
    prefix_characters,
    prefix_pixiv_id,
    prefix_member
)


class SorterResult:
    image_url: str | None
    image_bytes: bytes | None
    creator: str | None
    source: str | None
    material: str | None
    characters: str | None
    pixiv_id: str | None
    pixiv_member: str | None

    def __init__(
            self,

            # For Web
            element: ElementHandle | None = None,
            images: dict[str, bytes] | None = None,

            # For API
            image_bytes: bytes | None = None,
            creator: str | None = None,
            source: str | None = None,
            material: str | None = None,
            characters: str | None = None,
            pixiv_id: str | None = None,
            pixiv_member: str | None = None
    ):
        if element and images:
            # Get image from result
            if image_element := element.query_selector(f".{classname_div_result_image} img"):
                print(f"Image found: {image_element.inner_html()}")
                self.image_url = image_element.get_attribute("src")
                print(f"Image URL: {self.image_url}")
                if image_bytes := images.get(self.image_url):
                    print(f"Found downloaded image with size {len(image_bytes)} bytes")
                    self.image_bytes = image_bytes
                else:
                    print("Image not downloaded")
                    self.image_bytes = None
            else:
                self.image_url = None
                self.image_bytes = None

            # Get title (creator name) from result
            if result_title_element := element.query_selector(f".{classname_div_result_title}"):
                print(f"Title found: {result_title_element.inner_html()}")
                self.creator = result_title_element.text_content().replace(prefix_creator, "").strip()
            else:
                self.creator = None

            # Get content (source, material, characters) from result
            if content_elements := element.query_selector_all(f".{classname_div_result_content}"):
                print(f"Content found: {[element.inner_html() for element in content_elements]}")
                content_text_list: list[str] = [element.text_content() for element in content_elements]
                content = "\n".join(content_text_list)
                content_lines: list[str] = content.splitlines()

                for content_line in content_lines:
                    if content_line.startswith(prefix_source):
                        content_line_split: list[str] = content_line.split(prefix_material)
                        if len(content_line_split) == 2:
                            self.source = content_line_split[0].replace(prefix_source, "").strip()
                            self.material = content_line_split[1].strip()
                        else:
                            self.source = content_line.replace(prefix_source, "").strip()

                    elif content_line.startswith(prefix_characters):
                        self.characters = content_line.replace(prefix_characters, "").strip()

                    elif content_line.startswith(prefix_pixiv_id):
                        content_line_split: list[str] = content_line.split(prefix_member)
                        if len(content_line_split) == 2:
                            self.pixiv_id = content_line_split[0].replace(prefix_pixiv_id, "").strip()
                            self.pixiv_member = content_line_split[1].strip()
                        else:
                            self.pixiv_id = content_line.replace(prefix_pixiv_id, "").strip()
            else:
                self.source = None
                self.material = None
                self.characters = None
                self.pixiv_id = None
                self.pixiv_member = None

        else:
            self.image_url = None
            self.image_bytes = image_bytes
            self.creator = creator
            self.source = source
            self.material = material
            self.characters = characters
            self.pixiv_id = pixiv_id
            self.pixiv_member = pixiv_member

    def to_dict(self) -> dict[str, str | bytes]:
        return {
            "preview": self.image_bytes,
            "creator": self.creator,
            "source": self.source,
            "material": self.material,
            "characters": self.characters,
            "pixiv": {
                "id": self.pixiv_id,
                "member": self.pixiv_member
            }
        }
