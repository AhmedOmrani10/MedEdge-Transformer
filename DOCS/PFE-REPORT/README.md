# PFE Report - Modular LaTeX Structure

## Project Organization

```
├── main.tex                 (Main document - preamble + chapter includes)
├── parts/
│   ├── part1.tex           (Part I: Invasive Glucose Monitoring Methods)
│   ├── part2.tex           (Part II: Non-Invasive Glucose Monitoring Methods)
│   └── part3.tex           (Part III: Transformer Architecture & FPGA Implementation)
└── README.md               (This file)
```

## How to Use

### To compile:
```bash
pdflatex main.tex
bibtex main
pdflatex main.tex
pdflatex main.tex
```

### To enable/disable parts:
In `main.tex`, uncomment the parts you want to include:

```latex
% Currently active:
\input{parts/part1}

% To activate Part II:
% \input{parts/part2}

% To activate Part III:
% \input{parts/part3}
```

## File Descriptions

### main.tex
- Contains the document preamble (packages, formatting, page styles)
- Contains the title page
- Imports parts via `\input{parts/partX}`
- Contains the bibliography (all parts share one reference list)

### parts/part1.tex
- Complete Part I: Invasive Glucose Monitoring Methods
- 5 chapters: Fingerstick, CGM, Venous, Urine, Alternative Site Testing
- Includes conclusion and transition to Part II
- **Status: COMPLETE**

### parts/part2.tex
- Template for Part II: Non-Invasive Glucose Monitoring Methods
- Currently a placeholder
- **Status: TO BE WRITTEN**

### parts/part3.tex
- Template for Part III: Transformer Architecture & FPGA Implementation
- Currently a placeholder
- **Status: TO BE WRITTEN**

## Adding Content

To add a new chapter to any part:

1. Edit the corresponding `parts/partX.tex` file
2. Add your `\chapter{Title}` and content
3. References are shared across all parts (same bibliography)

## Notes

- All citations are collected in a single bibliography at the end
- Each part has its own `\part{}` directive for organization
- Page styles apply across all parts (headers/footers are consistent)
- Table of contents is auto-generated from chapter headings
