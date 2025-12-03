---
name: review
# description: "Review code changes for bugs, security issues, and best practice violations"
description: "コード変更をレビューし、バグ、セキュリティ問題、ベストプラクティス違反を特定"
category: utility
complexity: basic
mcp-servers: []
personas: []
---

## 概要

コード変更をレビューし、バグ、セキュリティ問題、ベストプラクティス違反を特定

# /sc:review - Code Review and Quality Assessment

## Triggers
- Code change review requests for pull requests or commits
- Pre-commit quality validation and security assessment needs
- Best practice compliance verification requirements
- Code quality improvement opportunity identification

## Usage
```
/sc:review [target] [--scope staged|changed|all] [--focus quality|security|performance] [--severity critical|all]
```

## Behavioral Flow
1. **Discover**: Identify changed files using git status and diff analysis
2. **Inspect**: Read and analyze code changes with multi-perspective evaluation
3. **Evaluate**: Apply comprehensive review criteria across quality dimensions
4. **Report**: Generate prioritized findings with severity ratings and recommendations
5. **Suggest**: Provide actionable improvement proposals with code examples

Key behaviors:
- Multi-perspective code review (bugs, security, performance, quality, best practices)
- Git-aware change detection and diff-based analysis
- Severity-based issue prioritization (🔴 Critical | 🟡 Warning | 🟢 Suggestion)
- Constructive feedback with specific improvement guidance and code examples

## Tool Coordination
- **Bash**: Git operations for change detection and diff analysis
- **Read**: Source code inspection and configuration review
- **Grep**: Pattern analysis for issue detection and code search
- **Glob**: File discovery and project structure analysis

## Review Criteria

### 1. Bugs and Potential Issues
- Logic errors and edge case handling gaps
- Null/undefined checks and exception handling
- Error propagation and recovery mechanisms

### 2. Security
- Injection vulnerabilities (SQL, XSS, command injection)
- Authentication and authorization issues
- Sensitive information exposure risks
- OWASP Top 10 compliance

### 3. Performance
- Inefficient algorithms and unnecessary loops
- Memory leak potential and resource management
- Database query optimization opportunities

### 4. Code Quality
- Readability and maintainability concerns
- Naming convention consistency
- Code duplication (DRY principle)
- Appropriate commenting and documentation

### 5. Best Practices
- Language-specific idioms and patterns
- Design pattern application opportunities
- Test coverage and quality
- Error handling standards

## Key Patterns
- **Change Detection**: `git status` + `git diff` → identify review scope
- **Multi-Domain Review**: Quality + Security + Performance → comprehensive assessment
- **Severity Assessment**: Issue classification → prioritized recommendations
- **Positive Feedback**: Identify good patterns and practices alongside issues

## Examples

### Review Staged Changes
```
/sc:review --scope staged
# Reviews all staged files awaiting commit
# Provides pre-commit quality and security assessment
```

### Focused Security Review
```
/sc:review src/auth --focus security
# Deep security analysis of authentication changes
# Identifies vulnerabilities with remediation guidance
```

### Pull Request Review
```
/sc:review --scope changed --severity critical
# Reviews all changed files since last commit
# Highlights only critical issues requiring immediate attention
```

### Comprehensive Review
```
/sc:review src/api --focus all
# Multi-perspective review covering all quality dimensions
# Generates comprehensive report with prioritized recommendations
```

## Output Format

Each issue is reported as:

**[重要度] ファイルパス:行番号**
- 問題の説明
- 改善提案
- 必要に応じてコード例

重要度: 🔴 Critical | 🟡 Warning | 🟢 Suggestion

## Boundaries

**Will:**
- Execute comprehensive code review with multi-perspective analysis
- Provide specific, actionable recommendations with code examples
- Identify both issues and good practices worth highlighting
- Generate severity-prioritized findings for effective triage

**Will Not:**
- Automatically apply fixes without explicit user consent
- Review external dependencies beyond import and usage patterns
- Disable or bypass tests to achieve quality metrics
- Compromise system integrity for short-term results
