const year = new Date().getFullYear();
const translations = {
    'zh': {
        'logoText': '流光倒计时',
        'heroH1': '一按一拉，<span class="gradient-text">静待流光</span>',
        'heroP': '专为 macOS 设计的极简计时器。原生液态玻璃视觉，细腻星辰粒子动效，让每一次等待都充满仪式感。',
        'downloadBtn': '立即下载',
        'githubBtn': 'GitHub',
        'feat1Title': '线性触拽，精准定义',
        'feat1Desc': '独特的手柄拖拽交互，指尖滑动间精准定位每一秒。这是对时间的物理掌控感。',
        'feat2Title': '流光悬浮微岛',
        'feat2Desc': '优雅的系统级悬浮通知，关键提醒如流光般轻盈跃动，不干扰，更懂你。',
        'islandText': '流光倒计时：12:00 结束',
        'feat3Title': '极致简约主义',
        'feat3Desc': '剔除冗余干扰，界面纯粹通透，让计时效率回归直觉。',
        'feat4Title': '星辰粒子动效',
        'feat4Desc': '精细粒子交互渲染，每一次设定都是一次充满仪式感的视觉盛宴。',
        'feat5Title': '液态玻璃美学',
        'feat5Desc': '原生级磨砂材质与动态光影，与现代 macOS 桌面完美浑然一体。',
        'extraTitle': '更多精致细节',
        'detail1Title': '智能时刻预览',
        'detail1Desc': '拖拽时实时显示预计结束的具体时刻，掌控节奏，从容不迫。',
        'detail2Title': '一键场景预设',
        'detail2Desc': '快速开启泡面、专注或小睡模式，点击即刻进入高效状态。',
        'detail3Title': '原生键盘交互',
        'detail3Desc': '支持直接输入数字修改时间，灵活应对各种快速计时需求。',
        'detail4Title': '42度圆角曲率',
        'detail4Desc': '深度适配 Apple 级 42° 连续圆弧，摒弃直角，让每一处转角都流溢着自然的温润质感。',
        'footerPrivacy': '本网站不收集、不追踪、不存储任何访问数据。',
        'footerContact': '任何建议或意见请发邮件至：',
        'footerCopyright': `© 2015-${year} 流光倒计时. 来自`,
        'footerSupport': ' · 您可以',
        'footerDonate': '打赏',
        'footerSupportPost': '以支持我的创作',
        'footerFiling': '<a href="http://www.beian.gov.cn/portal/registerSystemInfo?recordcode=51012202000770" target="_blank">川公网安备51012202000770号</a>  <a href="https://beian.miit.gov.cn/" target="_blank">蜀ICP备2020028542号</a>'
    },
    'en': {
        'logoText': 'Flux Timer',
        'heroH1': 'Flow of Light, <span class="gradient-text">Mastered</span>',
        'heroP': 'Minimalist timer for macOS. Native liquid glass aesthetics with cosmic particle effects, turning every wait into a ceremony.',
        'downloadBtn': 'Download Now',
        'githubBtn': 'GitHub',
        'feat1Title': 'Linear Drag Interaction',
        'feat1Desc': 'Unique handle drag interaction for precise timing. A tactile way to master your seconds.',
        'feat2Title': 'Flux Dynamic Island',
        'feat2Desc': 'Elegant system-level floating notifications. Important reminders leap like light, without distraction.',
        'islandText': 'Flux Timer: Ends at 12:00',
        'feat3Title': 'Pure Minimalism',
        'feat3Desc': 'Removing all redundancy. A pure, transparent interface that returns efficiency to intuition.',
        'feat4Title': 'Stellar Particles',
        'feat4Desc': 'Fine particle rendering makes every setting a refined visual feast.',
        'feat5Title': 'Liquid Glass Aesthetic',
        'feat5Desc': 'Native frosted gradients and dynamic lights blending perfectly with modern macOS.',
        'extraTitle': 'Refined Details',
        'detail1Title': 'Smart Preview',
        'detail1Desc': 'Real-time completion preview while dragging. Stay in control of your rhythm.',
        'detail2Title': 'One-Click Presets',
        'detail2Desc': 'Quickly start Noodles, Focus, or Nap modes. Enter high-efficiency states instantly.',
        'detail3Title': 'Native Keyboard Input',
        'detail3Desc': 'Directly type numbers to set time. Flexible for all your quick timing needs.',
        'detail4Title': '42° Corner Curvature',
        'detail4Desc': 'Apple-style 42° continuous arcs. Every corner flows with natural comfort by abandoning sharp angles.',
        'footerPrivacy': 'This website does not collect, track, or store any visitor data.',
        'footerContact': 'Any suggestions or comments, please email:',
        'footerCopyright': `© 2015-${year} Flux Timer. From`,
        'footerSupport': ' · You can',
        'footerDonate': 'Donate',
        'footerSupportPost': ' to support my creation.',
        'footerFiling': '<a href="http://www.beian.gov.cn/portal/registerSystemInfo?recordcode=51012202000770" target="_blank">川公网安备51012202000770号</a>  <a href="https://beian.miit.gov.cn/" target="_blank">蜀ICP备2020028542号</a>'
    }
};

let currentLang = 'zh';

function updateLanguage() {
    document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        if (translations[currentLang][key]) {
            el.innerHTML = translations[currentLang][key];
        }
    });
    document.getElementById('lang-btn-text').textContent = currentLang === 'zh' ? 'EN' : 'ZH';
}

document.getElementById('lang-toggle').addEventListener('click', () => {
    currentLang = currentLang === 'zh' ? 'en' : 'zh';
    updateLanguage();
});

// Theme Toggle
const themeToggle = document.getElementById('theme-toggle');
let isDark = window.matchMedia('(prefers-color-scheme: dark)').matches;

function updateTheme() {
    document.body.setAttribute('data-theme', isDark ? 'dark' : 'light');
    const themeIcon = document.getElementById('theme-icon');
    if (isDark) {
        themeIcon.innerHTML = '<path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path>';
    } else {
        themeIcon.innerHTML = '<circle cx="12" cy="12" r="5"></circle><line x1="12" y1="1" x2="12" y2="3"></line><line x1="12" y1="21" x2="12" y2="23"></line><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line><line x1="1" y1="12" x2="3" y2="12"></line><line x1="21" y1="12" x2="23" y2="12"></line><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line>';
    }
}

themeToggle.addEventListener('click', () => {
    isDark = !isDark;
    updateTheme();
});

// Initialize
updateTheme();
updateLanguage();
