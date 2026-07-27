#!/usr/bin/env python3
"""
Generate AGENTS.md files for projects

This script analyzes a project directory and generates an AGENTS.md file
with appropriate sections based on the detected technology stack and project structure.

Usage:
    python generate_agents_md.py <target_folder> [--output <output_file>]
"""

import os
import sys
import json
import argparse
from pathlib import Path
from typing import Dict, List, Set, Optional


class ProjectAnalyzer:
    """Analyze project structure and detect technology stack"""
    
    def __init__(self, project_path: str):
        self.project_path = Path(project_path)
        self.tech_stack = {}
        self.build_system = {}
        self.test_framework = {}
        self.code_style = {}
        
    def analyze(self) -> Dict:
        """Run all analysis methods and return results"""
        return {
            'tech_stack': self.detect_tech_stack(),
            'build_system': self.detect_build_system(),
            'test_framework': self.detect_test_framework(),
            'code_style': self.detect_code_style(),
            'project_structure': self.analyze_structure(),
            'dependencies': self.get_dependencies()
        }
    
    def detect_tech_stack(self) -> Dict[str, str]:
        """Detect programming languages and frameworks"""
        stack = {}
        
        # JavaScript/TypeScript projects
        if (self.project_path / 'package.json').exists():
            with open(self.project_path / 'package.json', 'r') as f:
                pkg = json.load(f)
                deps = {**pkg.get('dependencies', {}), **pkg.get('devDependencies', {})}
                
                # Detect framework
                if 'react' in deps:
                    stack['framework'] = f"React {deps.get('react', '').lstrip('^~')}"
                elif 'vue' in deps:
                    stack['framework'] = f"Vue {deps.get('vue', '').lstrip('^~')}"
                elif 'angular' in deps or '@angular/core' in deps:
                    stack['framework'] = 'Angular'
                elif 'next' in deps:
                    stack['framework'] = f"Next.js {deps.get('next', '').lstrip('^~')}"
                elif 'express' in deps:
                    stack['framework'] = 'Express'
                
                # Detect build tool
                if 'vite' in deps:
                    stack['build_tool'] = 'Vite'
                elif 'webpack' in deps:
                    stack['build_tool'] = 'Webpack'
                elif '@parcel' in str(deps):
                    stack['build_tool'] = 'Parcel'
                
                # Detect TypeScript
                if 'typescript' in deps or (self.project_path / 'tsconfig.json').exists():
                    stack['language'] = f"TypeScript {deps.get('typescript', '').lstrip('^~')}"
                else:
                    stack['language'] = 'JavaScript'
        
        # Python projects
        elif (self.project_path / 'requirements.txt').exists() or \
             (self.project_path / 'pyproject.toml').exists() or \
             (self.project_path / 'setup.py').exists():
            stack['language'] = 'Python'
            
            if (self.project_path / 'pyproject.toml').exists():
                # Could parse pyproject.toml for framework detection
                pass
            
            # Check for Django
            if (self.project_path / 'manage.py').exists():
                stack['framework'] = 'Django'
            # Check for Flask
            elif any(self.project_path.glob('**/app.py')) or \
                 any(self.project_path.glob('**/application.py')):
                stack['framework'] = 'Flask'
        
        # Go projects
        elif (self.project_path / 'go.mod').exists():
            stack['language'] = 'Go'
        
        # Rust projects
        elif (self.project_path / 'Cargo.toml').exists():
            stack['language'] = 'Rust'
        
        # Java projects
        elif (self.project_path / 'pom.xml').exists():
            stack['language'] = 'Java'
            stack['build_tool'] = 'Maven'
        elif (self.project_path / 'build.gradle').exists() or \
             (self.project_path / 'build.gradle.kts').exists():
            stack['language'] = 'Java/Kotlin'
            stack['build_tool'] = 'Gradle'
        
        return stack
    
    def detect_build_system(self) -> Dict[str, List[str]]:
        """Detect build commands and package manager"""
        build_info = {
            'package_manager': None,
            'commands': {
                'install': [],
                'dev': [],
                'build': [],
                'test': [],
                'lint': []
            }
        }
        
        # Node.js projects
        if (self.project_path / 'package.json').exists():
            with open(self.project_path / 'package.json', 'r') as f:
                pkg = json.load(f)
                scripts = pkg.get('scripts', {})
            
            # Detect package manager
            if (self.project_path / 'pnpm-lock.yaml').exists():
                pm = 'pnpm'
            elif (self.project_path / 'yarn.lock').exists():
                pm = 'yarn'
            else:
                pm = 'npm'
            
            build_info['package_manager'] = pm
            
            # Extract commands
            build_info['commands']['install'] = [f'{pm} install']
            
            if 'dev' in scripts or 'start' in scripts:
                build_info['commands']['dev'] = [f'{pm} run dev' if 'dev' in scripts else f'{pm} start']
            
            if 'build' in scripts:
                build_info['commands']['build'] = [f'{pm} run build']
            
            if 'test' in scripts:
                build_info['commands']['test'] = [f'{pm} test']
            
            if 'lint' in scripts:
                build_info['commands']['lint'] = [f'{pm} run lint']
        
        # Python projects
        elif (self.project_path / 'requirements.txt').exists() or \
             (self.project_path / 'pyproject.toml').exists():
            build_info['package_manager'] = 'pip'
            
            if (self.project_path / 'requirements.txt').exists():
                build_info['commands']['install'] = ['pip install -r requirements.txt']
            elif (self.project_path / 'pyproject.toml').exists():
                build_info['commands']['install'] = ['pip install -e .']
            
            # Django commands
            if (self.project_path / 'manage.py').exists():
                build_info['commands']['dev'] = ['python manage.py runserver']
                build_info['commands']['test'] = ['python manage.py test']
            else:
                build_info['commands']['test'] = ['pytest']
        
        # Go projects
        elif (self.project_path / 'go.mod').exists():
            build_info['package_manager'] = 'go'
            build_info['commands']['install'] = ['go mod download']
            build_info['commands']['build'] = ['go build ./...']
            build_info['commands']['test'] = ['go test ./...']
        
        # Rust projects
        elif (self.project_path / 'Cargo.toml').exists():
            build_info['package_manager'] = 'cargo'
            build_info['commands']['install'] = ['cargo fetch']
            build_info['commands']['build'] = ['cargo build']
            build_info['commands']['dev'] = ['cargo run']
            build_info['commands']['test'] = ['cargo test']
        
        return build_info
    
    def detect_test_framework(self) -> Dict[str, str]:
        """Detect testing framework"""
        test_info = {}
        
        if (self.project_path / 'package.json').exists():
            with open(self.project_path / 'package.json', 'r') as f:
                pkg = json.load(f)
                deps = {**pkg.get('dependencies', {}), **pkg.get('devDependencies', {})}
            
            if 'vitest' in deps:
                test_info['framework'] = 'Vitest'
            elif 'jest' in deps:
                test_info['framework'] = 'Jest'
            elif 'mocha' in deps:
                test_info['framework'] = 'Mocha'
            elif 'playwright' in deps or '@playwright/test' in deps:
                test_info['e2e'] = 'Playwright'
            elif 'cypress' in deps:
                test_info['e2e'] = 'Cypress'
        
        elif (self.project_path / 'requirements.txt').exists() or \
             (self.project_path / 'pyproject.toml').exists():
            if any(f.name.startswith('pytest') for f in self.project_path.glob('**/*') if f.is_file()):
                test_info['framework'] = 'pytest'
            elif (self.project_path / 'manage.py').exists():
                test_info['framework'] = 'Django Test'
        
        return test_info
    
    def detect_code_style(self) -> Dict[str, str]:
        """Detect code style tools and configuration"""
        style_info = {}
        
        # JavaScript/TypeScript
        if (self.project_path / '.eslintrc.json').exists() or \
           (self.project_path / '.eslintrc.js').exists() or \
           (self.project_path / '.eslintrc.yml').exists():
            style_info['linter'] = 'ESLint'
        
        if (self.project_path / '.prettierrc').exists() or \
           (self.project_path / '.prettierrc.json').exists() or \
           (self.project_path / 'prettier.config.js').exists():
            style_info['formatter'] = 'Prettier'
        
        # Python
        if (self.project_path / 'pyproject.toml').exists():
            with open(self.project_path / 'pyproject.toml', 'r') as f:
                content = f.read()
                if 'black' in content:
                    style_info['formatter'] = 'Black'
                if 'flake8' in content:
                    style_info['linter'] = 'flake8'
                if 'mypy' in content:
                    style_info['type_checker'] = 'mypy'
        
        # Go
        if (self.project_path / 'go.mod').exists():
            style_info['formatter'] = 'gofmt'
            style_info['linter'] = 'golangci-lint'
        
        # Rust
        if (self.project_path / 'Cargo.toml').exists():
            style_info['formatter'] = 'rustfmt'
            style_info['linter'] = 'clippy'
        
        return style_info
    
    def analyze_structure(self) -> Dict[str, str]:
        """Analyze project directory structure"""
        structure = {}
        
        common_dirs = {
            'src': 'Source code',
            'lib': 'Library code',
            'app': 'Application code',
            'tests': 'Test files',
            'test': 'Test files',
            'docs': 'Documentation',
            'scripts': 'Build/utility scripts',
            'public': 'Static assets',
            'assets': 'Assets',
            'components': 'React/Vue components',
            'pages': 'Application pages',
            'api': 'API routes',
            'services': 'Service layer',
            'utils': 'Utility functions',
            'hooks': 'React hooks',
            'styles': 'Style files'
        }
        
        for dir_name, description in common_dirs.items():
            dir_path = self.project_path / dir_name
            if dir_path.exists() and dir_path.is_dir():
                structure[dir_name] = description
        
        return structure
    
    def get_dependencies(self) -> List[str]:
        """Get list of main dependencies"""
        deps = []
        
        if (self.project_path / 'package.json').exists():
            with open(self.project_path / 'package.json', 'r') as f:
                pkg = json.load(f)
                deps = list(pkg.get('dependencies', {}).keys())[:10]  # Top 10
        
        return deps


class AgentsMdGenerator:
    """Generate AGENTS.md content based on project analysis"""
    
    def __init__(self, analysis: Dict):
        self.analysis = analysis
    
    def generate(self) -> str:
        """Generate complete AGENTS.md content"""
        sections = [
            self.generate_header(),
            self.generate_setup_section(),
            self.generate_testing_section(),
            self.generate_project_structure_section(),
            self.generate_code_style_section(),
            self.generate_git_workflow_section(),
            self.generate_boundaries_section()
        ]
        
        # Filter out empty sections
        sections = [s for s in sections if s.strip()]
        
        return '\n\n'.join(sections)
    
    def generate_header(self) -> str:
        """Generate overview section"""
        tech = self.analysis['tech_stack']
        
        if not tech:
            return "# AGENTS.md\n\nProject documentation for AI coding agents."
        
        parts = []
        if 'language' in tech:
            parts.append(tech['language'])
        if 'framework' in tech:
            parts.append(tech['framework'])
        if 'build_tool' in tech:
            parts.append(tech['build_tool'])
        
        stack_desc = ', '.join(parts) if parts else ''
        
        return f"""# AGENTS.md

## Overview

**Tech Stack**: {stack_desc}"""
    
    def generate_setup_section(self) -> str:
        """Generate setup commands section"""
        build = self.analysis['build_system']
        commands = build.get('commands', {})
        
        if not any(commands.values()):
            return ""
        
        lines = ["## Setup Commands\n"]
        
        if commands.get('install'):
            lines.append(f"- Install dependencies: `{commands['install'][0]}`")
        
        if commands.get('dev'):
            lines.append(f"- Start dev server: `{commands['dev'][0]}`")
        
        if commands.get('build'):
            lines.append(f"- Build: `{commands['build'][0]}`")
        
        return '\n'.join(lines)
    
    def generate_testing_section(self) -> str:
        """Generate testing section"""
        build = self.analysis['build_system']
        test_fw = self.analysis['test_framework']
        commands = build.get('commands', {})
        
        if not commands.get('test'):
            return ""
        
        lines = ["## Testing\n"]
        
        if test_fw.get('framework'):
            lines.append(f"**Framework**: {test_fw['framework']}\n")
        
        lines.append(f"- Run all tests: `{commands['test'][0]}`")
        
        # Add common test variations based on framework
        if test_fw.get('framework') == 'Jest' or test_fw.get('framework') == 'Vitest':
            pm = build.get('package_manager', 'npm')
            lines.append(f"- Watch mode: `{pm} test -- --watch`")
            lines.append(f"- Coverage: `{pm} test -- --coverage`")
        elif test_fw.get('framework') == 'pytest':
            lines.append('- Coverage: `pytest --cov=src`')
            lines.append('- Verbose: `pytest -v`')
        elif 'go' in str(commands.get('test')):
            lines.append('- Coverage: `go test -cover ./...`')
            lines.append('- Verbose: `go test -v ./...`')
        
        lines.append('\nAll tests must pass before committing.')
        
        return '\n'.join(lines)
    
    def generate_project_structure_section(self) -> str:
        """Generate project structure section"""
        structure = self.analysis['project_structure']
        
        if not structure:
            return ""
        
        lines = ["## Project Structure\n"]
        
        for dir_name, description in structure.items():
            lines.append(f"- `{dir_name}/` - {description}")
        
        return '\n'.join(lines)
    
    def generate_code_style_section(self) -> str:
        """Generate code style section"""
        style = self.analysis['code_style']
        tech = self.analysis['tech_stack']
        build = self.analysis['build_system']
        
        if not style and not tech.get('language'):
            return ""
        
        lines = ["## Code Style\n"]
        
        # Language info
        if tech.get('language'):
            lang = tech['language']
            if 'TypeScript' in lang:
                lines.append('- **Language**: TypeScript strict mode')
            else:
                lines.append(f"- **Language**: {lang}")
        
        # Linter/formatter
        if style.get('linter'):
            lines.append(f"- **Linter**: {style['linter']}")
        if style.get('formatter'):
            lines.append(f"- **Formatter**: {style['formatter']}")
        
        # Lint command
        if build.get('commands', {}).get('lint'):
            lines.append(f"\nRun linter: `{build['commands']['lint'][0]}`")
        
        # Add common conventions based on language
        if 'TypeScript' in tech.get('language', '') or 'JavaScript' in tech.get('language', ''):
            lines.append('\n### Naming Conventions')
            lines.append('- Functions/variables: camelCase')
            lines.append('- Components/Classes: PascalCase')
            lines.append('- Constants: UPPER_SNAKE_CASE')
            lines.append('- Files: kebab-case')
        elif 'Python' in tech.get('language', ''):
            lines.append('\n### Naming Conventions')
            lines.append('- Functions/variables: snake_case')
            lines.append('- Classes: PascalCase')
            lines.append('- Constants: UPPER_SNAKE_CASE')
        elif 'Go' in tech.get('language', ''):
            lines.append('\n### Naming Conventions')
            lines.append('- Exported: PascalCase')
            lines.append('- Unexported: camelCase')
            lines.append('- Interfaces: end with -er suffix')
        
        return '\n'.join(lines)
    
    def generate_git_workflow_section(self) -> str:
        """Generate git workflow section"""
        return """## Git Workflow

- **Branches**: `feature/`, `fix/`, `docs/` prefixes
- **Commits**: Use Conventional Commits format
  - `feat: add new feature`
  - `fix: resolve bug`
  - `docs: update documentation`
- **PRs**: All tests must pass, include description"""
    
    def generate_boundaries_section(self) -> str:
        """Generate boundaries section"""
        tech = self.analysis['tech_stack']
        build = self.analysis['build_system']
        
        test_cmd = build.get('commands', {}).get('test', ['tests'])[0]
        
        # Build Never section based on tech stack
        never_items = ['Commit secrets or API keys']
        
        if build.get('package_manager') in ['npm', 'yarn', 'pnpm']:
            never_items.append('Edit `node_modules/`')
        elif 'Python' in tech.get('language', ''):
            never_items.append('Edit `venv/` or virtual environment')
        elif 'Go' in tech.get('language', ''):
            never_items.append('Edit `vendor/` directory')
        
        never_items.append('Remove failing tests without fixing the code')
        never_items.append('Push code that fails tests or linting')
        
        return f"""## Boundaries

### ✅ Always Do
- Run `{test_cmd}` before committing
- Follow naming conventions
- Write or update tests for code changes
- Use proper error handling
- Add comments for complex logic

### ⚠️ Ask First
- Database schema changes
- Adding new dependencies
- Modifying CI/CD configuration
- Large refactoring affecting multiple files
- Changing build configuration

### 🚫 Never Do
- {chr(10).join('- ' + item for item in never_items)}"""


def main():
    parser = argparse.ArgumentParser(description='Generate AGENTS.md file for a project')
    parser.add_argument('target_folder', help='Path to the project folder')
    parser.add_argument('--output', '-o', help='Output file path (default: AGENTS.md in target folder)')
    
    args = parser.parse_args()
    
    target_path = Path(args.target_folder)
    if not target_path.exists():
        print(f"Error: Target folder '{args.target_folder}' does not exist", file=sys.stderr)
        sys.exit(1)
    
    if not target_path.is_dir():
        print(f"Error: '{args.target_folder}' is not a directory", file=sys.stderr)
        sys.exit(1)
    
    # Analyze project
    print(f"Analyzing project in {target_path}...")
    analyzer = ProjectAnalyzer(target_path)
    analysis = analyzer.analyze()
    
    print(f"Detected: {analysis['tech_stack'].get('language', 'Unknown')} project")
    
    # Generate AGENTS.md
    generator = AgentsMdGenerator(analysis)
    content = generator.generate()
    
    # Determine output path
    output_path = Path(args.output) if args.output else target_path / 'AGENTS.md'
    
    # Write file
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"\n✓ Generated AGENTS.md at: {output_path}")
    print("\nNext steps:")
    print("1. Review the generated file for accuracy")
    print("2. Add project-specific context and examples")
    print("3. Verify all commands work correctly")
    print("4. Add security boundaries if needed")


if __name__ == '__main__':
    main()
