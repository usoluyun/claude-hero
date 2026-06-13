---
agents:
  - name: hero-java-tech-lead
    display_name: 孔明
    model: opus
    role_type: planner
    readonly: false
    skills: [brainstorming, writing-plans]
    triggers: [架构设计, 任务拆解, Sprint规划]

  - name: hero-java-backend-developer
    display_name: 文远
    model: sonnet
    role_type: executor
    readonly: false
    skills: [hero-conventions, tdd]
    triggers: [实现接口, Controller, Service]

  - name: hero-java-data-engineer
    display_name: 子长
    model: sonnet
    role_type: executor
    readonly: false
    skills: [hero-maven, hero-pg-glimpse]
    triggers: [SQL, MyBatis, Mapper, DBA]

  - name: hero-java-test-engineer
    display_name: 希仁
    model: sonnet
    role_type: executor
    readonly: false
    skills: [tdd, playwright, gherkin]
    triggers: [单元测试, TDD, BDD, Playwright]

  - name: hero-java-code-reviewer
    display_name: 玄成
    model: opus
    role_type: reviewer
    readonly: true
    skills: [hero-pmd, hero-spotbugs, hero-semgrep]
    triggers: [代码审查, review, 质量]

  - name: hero-java-security-auditor
    display_name: 鹏举
    model: opus
    role_type: reviewer
    readonly: true
    skills: [hero-semgrep, hero-sca]
    triggers: [安全审计, security, OWASP]

  - name: hero-java-ecrm
    display_name: 子文
    model: sonnet
    role_type: navigator
    readonly: true
    skills: [hero-codegraph]
    triggers: [ecrm, 企业CRM, 审批]

  - name: hero-java-hotel-product-center
    display_name: 郑和
    model: sonnet
    role_type: navigator
    readonly: true
    skills: [hero-codegraph]
    triggers: [hotel-product, 房价码, 产品中心]

  - name: hero-java-owner-biz
    display_name: 霞客
    model: sonnet
    role_type: navigator
    readonly: true
    skills: [hero-codegraph]
    triggers: [owner-biz, 业主, 雅途]
---

# Agent Registry

| 花名 | agent | 类型 | model | readonly |
|------|-------|------|-------|----------|
| 孔明 | hero-java-tech-lead | planner | opus | no |
| 文远 | hero-java-backend-developer | executor | sonnet | no |
| 子长 | hero-java-data-engineer | executor | sonnet | no |
| 希仁 | hero-java-test-engineer | executor | sonnet | no |
| 玄成 | hero-java-code-reviewer | reviewer | opus | yes |
| 鹏举 | hero-java-security-auditor | reviewer | opus | yes |
| 子文 | hero-java-ecrm | navigator | sonnet | yes |
| 郑和 | hero-java-hotel-product-center | navigator | sonnet | yes |
| 霞客 | hero-java-owner-biz | navigator | sonnet | yes |
