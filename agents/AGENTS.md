---
agents:
  - name: hero-java-tech-lead
    display_name: Demis Hassabis
    model: opus
    role_type: planner
    readonly: false
    skills: [brainstorming, writing-plans]
    triggers: [架构设计, 任务拆解, Sprint规划]

  - name: hero-java-backend-developer
    display_name: Jeff Dean
    model: sonnet
    role_type: executor
    readonly: false
    skills: [hero-conventions, tdd]
    triggers: [实现接口, Controller, Service]

  - name: hero-java-data-engineer
    display_name: Fei-Fei Li
    model: sonnet
    role_type: executor
    readonly: false
    skills: [hero-maven, hero-pg-glimpse]
    triggers: [SQL, MyBatis, Mapper, DBA]

  - name: hero-java-test-engineer
    display_name: Percy Liang
    model: sonnet
    role_type: executor
    readonly: false
    skills: [tdd, playwright, gherkin]
    triggers: [单元测试, TDD, BDD, Playwright]

  - name: hero-java-code-reviewer
    display_name: Chris Olah
    model: opus
    role_type: reviewer
    readonly: true
    skills: [hero-pmd, hero-spotbugs, hero-semgrep]
    triggers: [代码审查, review, 质量]

  - name: hero-java-security-auditor
    display_name: Jan Leike
    model: opus
    role_type: reviewer
    readonly: true
    skills: [hero-semgrep, hero-sca]
    triggers: [安全审计, security, OWASP]

  - name: hero-java-ecrm
    display_name: John Schulman
    model: sonnet
    role_type: navigator
    readonly: true
    skills: [hero-codegraph]
    triggers: [ecrm, 企业CRM, 审批]

  - name: hero-java-hotel-product-center
    display_name: Oriol Vinyals
    model: sonnet
    role_type: navigator
    readonly: true
    skills: [hero-codegraph]
    triggers: [hotel-product, 房价码, 产品中心]

  - name: hero-java-owner-biz
    display_name: David Silver
    model: sonnet
    role_type: navigator
    readonly: true
    skills: [hero-codegraph]
    triggers: [owner-biz, 业主, 雅途]
---

# Agent Registry

| 花名 | agent | 类型 | model | readonly |
|------|-------|------|-------|----------|
| Demis Hassabis | hero-java-tech-lead | planner | opus | no |
| Jeff Dean | hero-java-backend-developer | executor | sonnet | no |
| Fei-Fei Li | hero-java-data-engineer | executor | opus | no |
| Percy Liang | hero-java-test-engineer | executor | sonnet | no |
| Chris Olah | hero-java-code-reviewer | reviewer | opus | yes |
| Jan Leike | hero-java-security-auditor | reviewer | opus | yes |
| John Schulman | hero-java-ecrm | navigator | sonnet | yes |
| Oriol Vinyals | hero-java-hotel-product-center | navigator | sonnet | yes |
| David Silver | hero-java-owner-biz | navigator | sonnet | yes |
