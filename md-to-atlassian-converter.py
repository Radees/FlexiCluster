#!/usr/bin/env python3
"""
Markdown to Atlassian Document Format Converter

This script converts Markdown files to Atlassian document format (Confluence Wiki Markup).
Usage: python md_to_atlassian.py input.md output.txt
"""

import re
import sys
import os
import argparse
from pathlib import Path


class MarkdownToAtlassianConverter:
    def __init__(self):
        # Mapping table for common Markdown elements to Atlassian format
        self.conversion_patterns = [
            # Headers
            (r'^# (.+)$', r'h1. \1'),
            (r'^## (.+)$', r'h2. \1'),
            (r'^### (.+)$', r'h3. \1'),
            (r'^#### (.+)$', r'h4. \1'),
            (r'^##### (.+)$', r'h5. \1'),
            (r'^###### (.+)$', r'h6. \1'),
            
            # Bold and Italic
            (r'\*\*(.+?)\*\*', r'*\1*'),  # Bold
            (r'__(.+?)__', r'*\1*'),      # Bold alternative
            (r'\*(.+?)\*', r'_\1_'),      # Italic
            (r'_(.+?)_', r'_\1_'),        # Italic alternative
            
            # Lists
            # Unordered lists
            (r'^\* (.+)$', r'* \1'),
            (r'^\+ (.+)$', r'* \1'),
            (r'^- (.+)$', r'* \1'),
            # Ordered lists (convert 1. 2. etc to # format)
            (r'^\d+\. (.+)$', r'# \1'),
            
            # Links
            (r'\[(.+?)\]\((.+?)\)', r'[\2|\1]'),
            
            # Code blocks - Atlassian uses {code} tags
            (r'```(\w*)\n([\s\S]*?)```', r'{code:\1}\n\2\n{code}'),
            (r'`(.+?)`', r'{{{\1}}}'),  # Inline code
            
            # Blockquotes
            (r'^> (.+)$', r'bq. \1'),
            
            # Tables - this is a simplistic approach, actual table conversion is more complex
            # Start of table, convert |header1|header2| to ||header1||header2||
            (r'^\|(.+)\|$', lambda m: '||' + m.group(1).replace('|', '||') + '||'),
            
            # Horizontal rule
            (r'^---+$', r'----'),
            (r'^___+$', r'----'),
            (r'^\*\*\*+$', r'----'),
            
            # Images
            (r'!\[(.+?)\]\((.+?)\)', r'!\2!'),
        ]
        
        # Special handling for nested lists
        self.nested_list_pattern = re.compile(r'^( +)([*+-]|\d+\.) (.+)$')

    def convert_nested_lists(self, line):
        """Handle nested lists by calculating indentation level and adding appropriate markers."""
        match = self.nested_list_pattern.match(line)
        if match:
            indent_len = len(match.group(1))
            indent_level = indent_len // 2  # Assuming 2 spaces per level
            
            list_type = match.group(2)
            content = match.group(3)
            
            # For unordered lists
            if list_type in ['*', '+', '-']:
                return f"{'*' * (indent_level + 1)} {content}"
            # For ordered lists
            else:
                return f"{'#' * (indent_level + 1)} {content}"
        return line

    def convert_text(self, markdown_text):
        """Convert markdown text to Atlassian format."""
        lines = markdown_text.split('\n')
        converted_lines = []
        
        # Keep track of code blocks to avoid conversion inside them
        in_code_block = False
        code_content = []
        code_language = ""
        
        for line in lines:
            # Check if we're entering or leaving a code block
            if line.strip().startswith('```'):
                in_code_block = not in_code_block
                if in_code_block:
                    # Extract language if specified
                    language_match = re.match(r'^```(\w*)$', line.strip())
                    code_language = language_match.group(1) if language_match else ""
                    code_content = []
                else:
                    # End of code block, convert and add to result
                    code_text = '\n'.join(code_content)
                    converted_lines.append(f"{{code:{code_language}}}")
                    converted_lines.append(code_text)
                    converted_lines.append("{code}")
                continue
            
            # Inside code block, just collect content without converting
            if in_code_block:
                code_content.append(line)
                continue
            
            # Skip table separator rows (---|---) as they don't have an equivalent in Atlassian
            if re.match(r'^[\|\-:\s]+$', line) and '|' in line:
                continue
            
            # Apply regular conversion patterns
            converted_line = line
            for pattern, replacement in self.conversion_patterns:
                converted_line = re.sub(pattern, replacement, converted_line, flags=re.MULTILINE)
            
            # Handle nested lists (must be done after general patterns)
            if re.match(r'^ +[*+-]', line) or re.match(r'^ +\d+\.', line):
                converted_line = self.convert_nested_lists(line)
            
            converted_lines.append(converted_line)
        
        return '\n'.join(converted_lines)

    def convert_file(self, input_file, output_file):
        """Convert a markdown file to Atlassian format."""
        try:
            with open(input_file, 'r', encoding='utf-8') as f:
                markdown_content = f.read()
            
            atlassian_content = self.convert_text(markdown_content)
            
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(atlassian_content)
            
            return True
        except Exception as e:
            print(f"Error converting file: {e}")
            return False


def main():
    parser = argparse.ArgumentParser(description='Convert Markdown files to Atlassian format')
    parser.add_argument('input', help='Input Markdown file or directory')
    parser.add_argument('-o', '--output', help='Output file or directory (optional)')
    parser.add_argument('-r', '--recursive', action='store_true', help='Process directories recursively')
    
    args = parser.parse_args()
    
    converter = MarkdownToAtlassianConverter()
    
    input_path = Path(args.input)
    
    # Handle single file conversion
    if input_path.is_file():
        output_path = Path(args.output) if args.output else input_path.with_suffix('.confluence')
        if converter.convert_file(input_path, output_path):
            print(f"Successfully converted {input_path} to {output_path}")
        else:
            print(f"Failed to convert {input_path}")
        return
    
    # Handle directory conversion
    if input_path.is_dir():
        output_base = Path(args.output) if args.output else input_path
        
        # Create output directory if it doesn't exist
        if args.output and not output_base.exists():
            output_base.mkdir(parents=True)
        
        # Find all markdown files in directory
        if args.recursive:
            md_files = list(input_path.glob('**/*.md'))
        else:
            md_files = list(input_path.glob('*.md'))
        
        if not md_files:
            print(f"No markdown files found in {input_path}")
            return
        
        success_count = 0
        for md_file in md_files:
            # Determine relative path from input base to maintain directory structure
            if args.output:
                rel_path = md_file.relative_to(input_path)
                output_file = output_base / rel_path.with_suffix('.confluence')
                # Create parent directories if needed
                output_file.parent.mkdir(parents=True, exist_ok=True)
            else:
                output_file = md_file.with_suffix('.confluence')
            
            if converter.convert_file(md_file, output_file):
                print(f"Successfully converted {md_file} to {output_file}")
                success_count += 1
            else:
                print(f"Failed to convert {md_file}")
        
        print(f"Converted {success_count} out of {len(md_files)} files")


if __name__ == "__main__":
    main()