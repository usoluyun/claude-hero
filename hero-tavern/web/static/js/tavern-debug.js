// 调试脚本 - 检查 renderSessions 的输入输出
console.log('=== Tavern Debug ===');

// 拦截原始 renderSessions
const _originalRenderSessions = window.renderSessions;

window.renderSessions = function(sessions) {
  console.log('renderSessions called with', sessions.length, 'sessions');
  
  // 统计
  let activeCount = 0;
  let sleepingCount = 0;
  
  sessions.forEach(session => {
    const allSleeping = !session.agents ||
                        session.agents.length === 0 ||
                        session.agents.every(a => a.status === 'sleeping');
    if (allSleeping) {
      sleepingCount++;
    } else {
      activeCount++;
    }
  });
  
  console.log('Split: activeCount =', activeCount, 'sleepingCount =', sleepingCount);
  
  // 调用原始函数
  return _originalRenderSessions.call(this, sessions);
};

// 检查 fetch 结果
const _originalFetch = window.fetch;
window.fetch = function(...args) {
  return _originalFetch.apply(this, args).then(response => {
    if (args[0] && args[0].includes('/api/status')) {
      // 克隆 response 以便读取
      const cloned = response.clone();
      cloned.json().then(data => {
        console.log('API /api/status response:', data);
        if (data.sessions) {
          console.log('Sessions from API:', data.sessions.length);
          console.log('First 3 sessions:', data.sessions.slice(0, 3));
        }
      }).catch(err => console.error('Failed to parse API response:', err));
    }
    return response;
  });
};

console.log('Debug hooks installed. Refresh the page to see logs.');
