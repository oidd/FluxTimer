const i18n = {
    zh: {
        title: "轻待办 | 极致轻量的 macOS 任务管理",
        logoText: "轻待办",
        heroH1: "极致轻量，<span class='gradient-text'>随叫随到</span>",
        heroP: "专为 macOS 打造，原生液态玻璃设计，让待办事项如灵感般轻盈。",
        github: "在 GitHub 上查看",
        feature1Title: "原生液态玻璃",
        feature1Desc: "极致半透明模糊与动态光影，完美交融桌面。",
        feature2Title: "边缘吸附交互",
        feature2Desc: "贴边隐藏，悬停滑出。无感存在，随时响应。",
        feature3Title: "呼吸光晕提醒",
        feature3Desc: "优雅边缘彩色流光，感知重要时刻。",
        feature4Title: "灵活任务管理",
        feature4Desc: "更灵活的任务拆解与设置。",
        feature5Title: "沉浸式主题",
        feature5Desc: "随心切换亮色与暗色模式。",
        footerPrivacy: "本网站不收集、不追踪、不存储任何访问数据。",
        footerContact: "任何建议或意见请发邮件至：",
        footerCopyright: "© 2015-2026 轻待办. 来自",
        footerSupport: " · 您可以",
        footerDonate: "打赏",
        footerSupportPost: "以支持我的创作",
        footerFiling: '<a href="http://www.beian.gov.cn/portal/registerSystemInfo?recordcode=51012202000770" target="_blank">川公网安备51012202000770号</a>  <a href="https://beian.miit.gov.cn/" target="_blank">蜀ICP备2020028542号</a>',
        extraFeaturesTitle: "更多强大特性",
        extraFeat1Title: "待办事项自动分类",
        extraFeat1Desc: "智能归纳，井井有条。让你的每一天都清晰明了。",
        tagToday: "今天",
        tagImportant: "重要",
        tagCycle: "周期",
        tagPlan: "计划",
        tagCompleted: "完成",
        extraFeat2Title: "快速录入",
        extraFeat2Desc: "点击空白处直接录入，再点一次取消。灵感即刻捕捉。",
        extraFeat3Title: "智能时间识别",
        extraFeat3Desc: "输入内容包含日期或时间时，自动给出建议。",
        extraFeat4Title: "自动排序",
        extraFeat4Desc: "支持按截止时间自动排列所有事项，急缓可控。",
        extraFeat5Title: "全局快捷键",
        extraFeat5Desc: "自定义快捷键快速呼出窗口，随时待命。",
        extraFeat6Title: "延时待办",
        extraFeat6Desc: "对有提醒的待办事项增加快捷延时条，一键延时。",
        extraFeat7Title: "粒子动效",
        extraFeat7Desc: "激活快照条会显示粒子动效，细腻精致。",
    },
    en: {
        title: "Light To Do | Minimalist Productivity for macOS",
        logoText: "Light To Do",
        heroH1: "Minimalist, <span class='gradient-text'>Always Ready</span>",
        heroP: "Tailored for macOS with native liquid glass design, making tasks as light as inspiration.",
        github: "View on GitHub",
        feature1Title: "Native Liquid Glass",
        feature1Desc: "Exquisite transparency and dynamic lighting blends with your desktop.",
        feature2Title: "Edge Adhesion",
        feature2Desc: "Hides at the edge and slides out on hover. Zero footprint.",
        feature3Title: "Breathing Glow",
        feature3Desc: "Elegant ambient notifications that respect your focus.",
        feature4Title: "Task Management",
        feature4Desc: "Flexible task breakdown and management.",
        feature5Title: "Immersive Themes",
        feature5Desc: "Switch seamlessly between Light and Dark modes.",
        footerPrivacy: "No tracking, no cookies, no data collection. Truly private.",
        footerContact: "Feedback or suggestions? Email us: ",
        footerCopyright: "© 2015-2026 Light To Do. From ",
        footerSupport: " · You can ",
        footerDonate: "Donate",
        footerSupportPost: " to support my creations.",
        footerFiling: '<a href="http://www.beian.gov.cn/portal/registerSystemInfo?recordcode=51012202000770" target="_blank">川公网安备51012202000770号</a>  <a href="https://beian.miit.gov.cn/" target="_blank">蜀ICP备2020028542号</a>',
        extraFeaturesTitle: "More Powerful Features",
        extraFeat1Title: "Smart Classification",
        extraFeat1Desc: "Automatically organizes your tasks. Keep your day clear and structured.",
        tagToday: "Today",
        tagImportant: "Important",
        tagCycle: "Recurring",
        tagPlan: "Planned",
        tagCompleted: "Completed",
        extraFeat2Title: "Quick Entry",
        extraFeat2Desc: "Click anywhere to type, click again to cancel. Capture inspiration instantly.",
        extraFeat3Title: "Time Recognition",
        extraFeat3Desc: "Automatically suggests dates and times as you type.",
        extraFeat4Title: "Auto Sorting",
        extraFeat4Desc: "Sort tasks by deadline automatically. Manage urgency with ease.",
        extraFeat5Title: "Global Shortcuts",
        extraFeat5Desc: "Customizable hotkeys to summon the window anytime.",
        extraFeat6Title: "Task Snooze",
        extraFeat6Desc: "Quick snooze bar for reminded tasks, one-click delay.",
        extraFeat7Title: "Particle Effects",
        extraFeat7Desc: "Activating the snap strip reveals delicate particle animations.",
    }
};

let currentLang = localStorage.getItem('lang') || 'zh';
let currentTheme = localStorage.getItem('theme') || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');

function updateContent() {
    const content = i18n[currentLang];
    document.title = content.title;

    document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        if (content[key]) {
            el.innerHTML = content[key];
        }
    });

    document.documentElement.lang = currentLang === 'zh' ? 'zh-CN' : 'en';
}

function toggleLang() {
    currentLang = currentLang === 'zh' ? 'en' : 'zh';
    localStorage.setItem('lang', currentLang);
    updateContent();
    document.getElementById('lang-btn-text').textContent = currentLang.toUpperCase();
}

function toggleTheme() {
    currentTheme = currentTheme === 'light' ? 'dark' : 'light';
    localStorage.setItem('theme', currentTheme);
    document.documentElement.setAttribute('data-theme', currentTheme);
    updateThemeIcon();
    updateAppIcon();
}

function updateThemeIcon() {
    const icon = document.getElementById('theme-icon');
    if (currentTheme === 'dark') {
        icon.innerHTML = '<path d="M12 3c.132 0 .263 0 .393 0a7.5 7.5 0 0 0 7.92 12.446a9 9 0 1 1-8.313-12.454z"/>';
    } else {
        icon.innerHTML = '<circle cx="12" cy="12" r="5"/><path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42"/>';
    }
}

function updateAppIcon() {
    const iconImg = document.getElementById('app-icon');
    if (iconImg) {
        iconImg.src = currentTheme === 'dark' ? 'icon_dark.png' : 'icon_light.png';
    }
}

// Init
document.addEventListener('DOMContentLoaded', () => {
    document.documentElement.setAttribute('data-theme', currentTheme);
    document.getElementById('lang-btn-text').textContent = currentLang.toUpperCase();
    updateThemeIcon();
    updateAppIcon();
    updateContent();

    document.getElementById('lang-toggle').addEventListener('click', toggleLang);
    document.getElementById('theme-toggle').addEventListener('click', toggleTheme);
});
