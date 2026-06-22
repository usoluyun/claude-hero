/**
 * claude-hero 滚动动画系统
 * 轻量级、无依赖、高性能
 */
(function() {
  'use strict';

  // ============ 配置 ============
  const CONFIG = {
    scrollThreshold: 0.15,
    animationDuration: 600,
    staggerDelay: 100
  };

  // ============ 工具函数 ============
  function debounce(func, wait) {
    let timeout;
    return function(...args) {
      clearTimeout(timeout);
      timeout = setTimeout(() => func.apply(this, args), wait);
    };
  }

  function isInViewport(element) {
    const rect = element.getBoundingClientRect();
    return (
      rect.top <= (window.innerHeight || document.documentElement.clientHeight) &&
      rect.bottom >= 0
    );
  }

  // ============ ScrollAnimator: 滚动触发动画 ============
  class ScrollAnimator {
    constructor() {
      this.observer = null;
      this.init();
    }

    init() {
      this.observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            this.animateElement(entry.target);
            this.observer.unobserve(entry.target);
          }
        });
      }, {
        threshold: CONFIG.scrollThreshold,
        rootMargin: '0px 0px -100px 0px'
      });

      document.querySelectorAll('.animate-on-scroll').forEach(el => {
        this.observer.observe(el);
      });
    }

    animateElement(element) {
      const animation = element.dataset.animation || 'fadeInUp';
      const delay = element.dataset.delay || 0;

      setTimeout(() => {
        element.classList.add('animated', animation);
      }, delay);
    }
  }

  // ============ TabSwitcher: Tab 切换逻辑 ============
  class TabSwitcher {
    constructor(container) {
      this.container = container;
      this.tabs = container.querySelectorAll('.tab-btn');
      this.contents = container.querySelectorAll('.tab-content');
      this.init();
    }

    init() {
      this.tabs.forEach(tab => {
        tab.addEventListener('click', () => {
          this.switchTab(tab.dataset.tab);
        });
      });
    }

    switchTab(tabId) {
      this.tabs.forEach(tab => {
        tab.classList.toggle('active', tab.dataset.tab === tabId);
      });

      this.contents.forEach(content => {
        content.classList.toggle('active', content.dataset.tab === tabId);
      });
    }
  }

  // ============ WorkflowDemo: 工作流演示器 ============
  class WorkflowDemo {
    constructor(container) {
      this.container = container;
      this.steps = container.querySelectorAll('.step');
      this.outputs = container.querySelectorAll('.output-panel');
      this.nextBtn = container.querySelector('.demo-next');
      this.currentStep = 0;
      this.totalSteps = this.steps.length;
      this.isAutoPlaying = false;
      this.autoPlayInterval = null;
      this.init();
    }

    init() {
      this.steps.forEach((step, index) => {
        step.addEventListener('click', () => {
          this.goToStep(index);
        });
      });

      if (this.nextBtn) {
        this.nextBtn.addEventListener('click', () => {
          this.nextStep();
        });
      }

      this.goToStep(0);
    }

    goToStep(index) {
      this.currentStep = index;

      this.steps.forEach((step, i) => {
        step.classList.toggle('active', i === index);
      });

      this.outputs.forEach((output, i) => {
        output.classList.toggle('active', i === index);
      });

      if (this.nextBtn) {
        if (index === this.totalSteps - 1) {
          this.nextBtn.textContent = '重新开始';
        } else {
          this.nextBtn.textContent = '查看下一步 →';
        }
      }
    }

    nextStep() {
      if (this.currentStep < this.totalSteps - 1) {
        this.goToStep(this.currentStep + 1);
      } else {
        this.goToStep(0);
      }
    }

    startAutoPlay(interval = 3000) {
      if (this.isAutoPlaying) return;
      this.isAutoPlaying = true;
      this.autoPlayInterval = setInterval(() => {
        this.nextStep();
      }, interval);
    }

    stopAutoPlay() {
      this.isAutoPlaying = false;
      if (this.autoPlayInterval) {
        clearInterval(this.autoPlayInterval);
      }
    }
  }

  // ============ FeatureAccordion: 特性卡片手风琴 ============
  class FeatureAccordion {
    constructor(container) {
      this.container = container;
      this.cards = container.querySelectorAll('.feature-card');
      this.init();
    }

    init() {
      this.cards.forEach(card => {
        const details = card.querySelector('.feature-details');
        if (!details) return;

        card.addEventListener('click', () => {
          this.toggleCard(card);
        });
      });
    }

    toggleCard(card) {
      const isExpanded = card.classList.contains('expanded');
      const details = card.querySelector('.feature-details');

      this.cards.forEach(c => {
        c.classList.remove('expanded');
        const d = c.querySelector('.feature-details');
        if (d) d.style.maxHeight = '0';
      });

      if (!isExpanded && details) {
        card.classList.add('expanded');
        details.style.maxHeight = details.scrollHeight + 'px';
      }
    }
  }

  // ============ SmoothScroll: 平滑滚动 ============
  class SmoothScroll {
    constructor() {
      this.init();
    }

    init() {
      document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', (e) => {
          const href = anchor.getAttribute('href');
          if (href === '#') return;

          const target = document.querySelector(href);
          if (target) {
            e.preventDefault();
            target.scrollIntoView({
              behavior: 'smooth',
              block: 'start'
            });

            history.pushState(null, null, href);
          }
        });
      });
    }
  }

  // ============ BackToTop: 回到顶部按钮 ============
  class BackToTop {
    constructor() {
      this.button = null;
      this.init();
    }

    init() {
      this.button = document.createElement('button');
      this.button.className = 'back-to-top';
      this.button.innerHTML = '↑';
      this.button.setAttribute('aria-label', '回到顶部');
      document.body.appendChild(this.button);

      window.addEventListener('scroll', debounce(() => {
        if (window.scrollY > 500) {
          this.button.classList.add('visible');
        } else {
          this.button.classList.remove('visible');
        }
      }, 100));

      this.button.addEventListener('click', () => {
        window.scrollTo({
          top: 0,
          behavior: 'smooth'
        });
      });
    }
  }

  // ============ 初始化 ============
  function init() {
    new ScrollAnimator();

    document.querySelectorAll('.skill-tabs').forEach(container => {
      new TabSwitcher(container);
    });

    document.querySelectorAll('.workflow-demo').forEach(container => {
      new WorkflowDemo(container);
    });

    document.querySelectorAll('.hidden-features').forEach(container => {
      new FeatureAccordion(container);
    });

    new SmoothScroll();
    new BackToTop();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
