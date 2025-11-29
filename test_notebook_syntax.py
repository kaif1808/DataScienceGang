#!/usr/bin/env python3
"""
Test script to verify the notebook syntax and identify any issues.
This script extracts and tests the Python code from the notebook.
"""

import json
import sys
import re

def test_notebook_syntax():
    """Test the syntax of Python code in the notebook."""
    
    try:
        with open('stroke_prediction_analysis.ipynb', 'r') as f:
            notebook = json.load(f)
        
        print("✅ Successfully loaded notebook JSON")
        
        if 'cells' not in notebook:
            print("❌ No cells found in notebook")
            return False
            
        print(f"📋 Found {len(notebook['cells'])} cells in notebook")
        
        # Find and test the data cleaning cell
        for i, cell in enumerate(notebook['cells']):
            if cell.get('cell_type') == 'code':
                source = ''.join(cell.get('source', []))
                
                # Look for the stroke_final data cleaning code
                if 'stroke_final = (' in source and '.with_columns(' in source:
                    print(f"🔍 Found data cleaning code in cell {i+1}")
                    
                    # Extract the code block
                    print("📝 Testing the extracted Python code...")
                    
                    # Write to a temp file for syntax checking
                    with open('temp_test_code.py', 'w') as f:
                        f.write(source)
                    
                    # Try to compile the code
                    try:
                        compile(source, '<notebook>', 'exec')
                        print("✅ Code compiles successfully - no syntax errors!")
                        return True
                    except SyntaxError as e:
                        print(f"❌ Syntax Error found:")
                        print(f"   File: <notebook>")
                        print(f"   Line {e.lineno}: {e.text.strip() if e.text else ''}")
                        print(f"   Error: {e.msg}")
                        print(f"   Position: {e.offset}")
                        return False
                    except Exception as e:
                        print(f"❌ Other error: {e}")
                        return False
        
        print("⚠️  Data cleaning code not found in expected format")
        return False
        
    except json.JSONDecodeError as e:
        print(f"❌ Invalid JSON in notebook: {e}")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def extract_specific_problem_area():
    """Extract and show the specific problematic area."""
    
    try:
        with open('stroke_prediction_analysis.ipynb', 'r') as f:
            notebook = json.load(f)
        
        for cell in notebook['cells']:
            if cell.get('cell_type') == 'code':
                source = ''.join(cell.get('source', []))
                
                if 'stroke_final = (' in source:
                    lines = source.split('\n')
                    print("\n🔍 Extracting specific lines around stroke_final:")
                    
                    for i, line in enumerate(lines[:25], 1):  # Show first 25 lines
                        print(f"{i:2d}: {line}")
                    
                    return True
                    
    except Exception as e:
        print(f"❌ Error extracting specific area: {e}")
        return False

if __name__ == "__main__":
    print("🧪 Testing Notebook Syntax\n")
    
    if test_notebook_syntax():
        print("\n✅ All syntax checks passed!")
        sys.exit(0)
    else:
        print("\n❌ Syntax issues found!")
        
        print("\n" + "="*50)
        print("📋 DETAILED CODE INSPECTION")
        print("="*50)
        extract_specific_problem_area()
        
        sys.exit(1)