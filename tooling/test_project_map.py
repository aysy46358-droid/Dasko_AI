"""Unit tests for the project-map inventory generator."""

import unittest

from tooling.project_map import (
    BEGIN_MARKER,
    END_MARKER,
    render_inventory,
    replace_generated_block,
)


class ProjectMapGeneratorTest(unittest.TestCase):
    def test_inventory_is_sorted_and_deduplicated(self) -> None:
        rendered = render_inventory(["z/file.dart", "a/file.dart", "z/file.dart"])
        self.assertEqual(rendered, "- `a/file.dart`\n- `z/file.dart`")

    def test_inventory_is_repeatable(self) -> None:
        paths = ["lib/main.dart", "docs/PROJECT_MAP.md", "README.md"]
        self.assertEqual(render_inventory(paths), render_inventory(paths))

    def test_replace_preserves_prose_outside_generated_block(self) -> None:
        source = f"before\n{BEGIN_MARKER}\nold\n{END_MARKER}\nafter\n"
        updated = replace_generated_block(source, "- `README.md`")
        self.assertEqual(
            updated,
            f"before\n{BEGIN_MARKER}\n- `README.md`\n{END_MARKER}\nafter\n",
        )

    def test_replace_rejects_missing_or_duplicate_markers(self) -> None:
        with self.assertRaises(ValueError):
            replace_generated_block("no markers", "content")
        duplicate = f"{BEGIN_MARKER}\n{BEGIN_MARKER}\n{END_MARKER}"
        with self.assertRaises(ValueError):
            replace_generated_block(duplicate, "content")

    def test_replace_rejects_reversed_markers(self) -> None:
        source = f"{END_MARKER}\n{BEGIN_MARKER}"
        with self.assertRaises(ValueError):
            replace_generated_block(source, "content")


if __name__ == "__main__":
    unittest.main()
