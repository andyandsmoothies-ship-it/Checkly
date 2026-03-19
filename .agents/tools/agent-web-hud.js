const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');

const PORT = 3005;
const BRAIN_DIR = path.join(os.homedir(), '.gemini', 'antigravity', 'brain');

function getLatestSession() {
    try {
        const dirs = fs.readdirSync(BRAIN_DIR, { withFileTypes: true })
            .filter(d => d.isDirectory())
            .map(d => {
                const fp = path.join(BRAIN_DIR, d.name);
                return { name: d.name, path: fp, time: fs.statSync(fp).mtimeMs };
            })
            .sort((a, b) => b.time - a.time);

        for (const dir of dirs) {
            const taskPath = path.join(dir.path, 'task.md');
            if (fs.existsSync(taskPath)) {
                return { taskPath, sessionId: dir.name };
            }
        }
    } catch (e) { }
    return null;
}

const HTML = `<!DOCTYPE html>
<html lang="en" class="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Agent Kanban — Live Progress</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js" defer></script>
    <script>
        tailwind.config = {
            darkMode: 'class',
            theme: { extend: { fontFamily: { sans: ['Inter', 'system-ui', 'sans-serif'] } } }
        }
    </script>
    <style>
        body { font-family: 'Inter', system-ui, sans-serif; }
        .glass { background: rgba(15, 23, 42, 0.6); backdrop-filter: blur(20px); }
        .card-glass { background: rgba(30, 41, 59, 0.5); backdrop-filter: blur(12px); }
        .glow-blue { box-shadow: 0 0 20px rgba(59, 130, 246, 0.15), inset 0 1px 0 rgba(255,255,255,0.05); }
        .glow-amber { box-shadow: 0 0 20px rgba(245, 158, 11, 0.15), inset 0 1px 0 rgba(255,255,255,0.05); }
        .glow-emerald { box-shadow: 0 0 20px rgba(16, 185, 129, 0.15), inset 0 1px 0 rgba(255,255,255,0.05); }
        .shimmer { background: linear-gradient(90deg, transparent, rgba(255,255,255,0.04), transparent); background-size: 200% 100%; animation: shimmer 2s infinite; }
        @keyframes shimmer { 0% { background-position: -200% 0; } 100% { background-position: 200% 0; } }
        @keyframes float { 0%,100% { transform: translateY(0); } 50% { transform: translateY(-4px); } }
        .float { animation: float 3s ease-in-out infinite; }
        .kanban-col { min-height: 520px; }
        ::-webkit-scrollbar { width: 4px; } ::-webkit-scrollbar-track { background: transparent; } ::-webkit-scrollbar-thumb { background: rgba(100,116,139,0.3); border-radius: 4px; }
    </style>
</head>
<body class="bg-[#0a0f1a] text-slate-200 min-h-screen antialiased overflow-x-hidden">

    <!-- Ambient Background -->
    <div class="fixed inset-0 z-[-1] pointer-events-none overflow-hidden">
        <div class="absolute top-[-20%] left-[-10%] w-[50%] h-[60%] rounded-full bg-blue-950/30 blur-[150px]"></div>
        <div class="absolute bottom-[-20%] right-[-5%] w-[45%] h-[55%] rounded-full bg-emerald-950/20 blur-[150px]"></div>
        <div class="absolute top-[30%] right-[20%] w-[30%] h-[30%] rounded-full bg-violet-950/15 blur-[120px]"></div>
    </div>

    <div x-data="kanban()" x-init="startPolling()" class="max-w-[1400px] mx-auto px-6 py-8 space-y-8">

        <!-- ═══════════ HEADER ═══════════ -->
        <div class="glass rounded-2xl border border-slate-800/80 p-6 flex flex-col lg:flex-row lg:items-center justify-between gap-4">
            <div class="flex items-center gap-5">
                <div class="relative flex h-4 w-4 items-center justify-center">
                    <span x-show="isPolling" class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-50"></span>
                    <span class="relative inline-flex rounded-full h-2.5 w-2.5" :class="isPolling ? 'bg-emerald-400 shadow-[0_0_8px_rgba(52,211,153,0.6)]' : 'bg-slate-600'"></span>
                </div>
                <div>
                    <h1 class="text-2xl font-extrabold tracking-tight bg-gradient-to-r from-white via-slate-200 to-slate-400 bg-clip-text text-transparent">Agent Kanban</h1>
                    <p class="text-xs text-slate-500 mt-0.5 font-medium tracking-wide" x-text="isPolling ? 'LIVE — polling task.md every second' : '✓ WORKFLOW COMPLETE — polling stopped'"></p>
                </div>
            </div>

            <!-- Stats Row -->
            <div class="flex items-center gap-3 flex-wrap">
                <!-- Timer -->
                <div class="flex items-center gap-2 px-4 py-2 rounded-xl bg-slate-900/60 border border-slate-800/80 text-sm">
                    <svg class="w-4 h-4 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                    <span class="text-slate-400 font-mono tabular-nums" x-text="elapsed"></span>
                </div>
                <!-- Progress Chip -->
                <div class="flex items-center gap-2 px-4 py-2 rounded-xl border text-sm font-semibold transition-all duration-500"
                     :class="progressPercentage === 100 ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-400' : 'bg-blue-500/10 border-blue-500/30 text-blue-400'">
                    <span x-text="progressPercentage + '%'"></span>
                </div>
                <!-- Counts -->
                <div class="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-slate-900/60 border border-slate-800/80 text-sm">
                    <span class="text-emerald-400 font-bold" x-text="doneCount"></span>
                    <span class="text-slate-600">/</span>
                    <span class="text-white font-bold" x-text="totalCount"></span>
                    <span class="text-slate-500 ml-1">tasks</span>
                </div>
            </div>
        </div>

        <!-- ═══════════ PROGRESS BAR ═══════════ -->
        <div class="h-1 w-full bg-slate-900 rounded-full overflow-hidden">
            <div class="h-full rounded-full transition-all duration-1000 ease-out relative"
                 :class="progressPercentage === 100 ? 'bg-gradient-to-r from-emerald-500 to-emerald-400' : 'bg-gradient-to-r from-blue-600 via-blue-500 to-cyan-400'"
                 :style="'width:' + progressPercentage + '%'">
                <div class="absolute inset-0 shimmer"></div>
            </div>
        </div>

        <!-- ═══════════ KANBAN BOARD ═══════════ -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">

            <!-- ── QUEUED Column ── -->
            <div class="space-y-4">
                <div class="flex items-center gap-3 px-1 mb-2">
                    <div class="w-2.5 h-2.5 rounded-full bg-slate-500"></div>
                    <h2 class="text-sm font-bold uppercase tracking-widest text-slate-400">Queued</h2>
                    <span class="ml-auto text-xs font-semibold text-slate-600 bg-slate-800/80 px-2.5 py-1 rounded-full" x-text="queuedCount"></span>
                </div>
                <div class="kanban-col space-y-3 overflow-y-auto pr-1" style="max-height: 65vh;">
                    <template x-if="queuedItems.length === 0 && totalCount > 0">
                        <div class="flex flex-col items-center justify-center py-16 text-slate-600">
                            <svg class="w-10 h-10 mb-3 opacity-30" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z"/></svg>
                            <p class="text-sm font-medium">Queue is clear!</p>
                        </div>
                    </template>
                    <template x-for="(item, i) in queuedItems" :key="'q'+i">
                        <div class="card-glass rounded-xl border border-slate-800/60 p-4 transition-all duration-300 hover:border-slate-700/80 group">
                            <div class="flex items-start gap-3">
                                <div class="mt-1 w-5 h-5 rounded border-2 border-slate-700 flex-shrink-0 group-hover:border-slate-600 transition-colors"></div>
                                <div>
                                    <p class="text-sm text-slate-400 leading-relaxed" x-text="item.text"></p>
                                    <template x-if="item.section">
                                        <span class="inline-block mt-2 text-[10px] font-semibold uppercase tracking-wider text-slate-600 bg-slate-800/60 px-2 py-0.5 rounded" x-text="item.section"></span>
                                    </template>
                                </div>
                            </div>
                        </div>
                    </template>
                </div>
            </div>

            <!-- ── ACTIVE Column ── -->
            <div class="space-y-4">
                <div class="flex items-center gap-3 px-1 mb-2">
                    <div class="w-2.5 h-2.5 rounded-full bg-blue-500 shadow-[0_0_6px_rgba(59,130,246,0.5)]"></div>
                    <h2 class="text-sm font-bold uppercase tracking-widest text-blue-400">In Progress</h2>
                    <span class="ml-auto text-xs font-semibold text-blue-400 bg-blue-500/10 px-2.5 py-1 rounded-full border border-blue-500/20" x-text="activeCount"></span>
                </div>
                <div class="kanban-col space-y-3 overflow-y-auto pr-1" style="max-height: 65vh;">
                    <template x-if="activeItems.length === 0">
                        <div class="flex flex-col items-center justify-center py-16 text-slate-600">
                            <template x-if="isPolling && totalCount > 0">
                                <div class="text-center">
                                    <div class="w-10 h-10 mx-auto mb-3 rounded-full border-2 border-blue-500/30 border-t-blue-400 animate-spin"></div>
                                    <p class="text-sm font-medium text-slate-500">Waiting for next task...</p>
                                </div>
                            </template>
                            <template x-if="!isPolling || totalCount === 0">
                                <div class="text-center">
                                    <svg class="w-10 h-10 mx-auto mb-3 opacity-20" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/></svg>
                                    <p class="text-sm font-medium">Idle</p>
                                </div>
                            </template>
                        </div>
                    </template>
                    <template x-for="(item, i) in activeItems" :key="'a'+i">
                        <div class="rounded-xl border border-blue-500/30 p-5 glow-blue transition-all duration-500 float" style="background: linear-gradient(135deg, rgba(30,58,138,0.25), rgba(15,23,42,0.8));">
                            <div class="flex items-start gap-3">
                                <div class="mt-0.5 flex-shrink-0">
                                    <div class="w-5 h-5 rounded-full border-2 border-blue-400 flex items-center justify-center">
                                        <div class="w-2 h-2 rounded-full bg-blue-400 animate-pulse"></div>
                                    </div>
                                </div>
                                <div class="flex-1">
                                    <p class="text-sm text-blue-50 font-medium leading-relaxed" x-text="item.text"></p>
                                    <template x-if="item.section">
                                        <span class="inline-block mt-2.5 text-[10px] font-semibold uppercase tracking-wider text-blue-400/70 bg-blue-500/10 px-2 py-0.5 rounded border border-blue-500/20" x-text="item.section"></span>
                                    </template>
                                    <!-- Active shimmer bar -->
                                    <div class="mt-4 h-1 w-full bg-slate-900/80 rounded-full overflow-hidden">
                                        <div class="h-full bg-gradient-to-r from-blue-600 to-cyan-400 rounded-full shimmer" style="width:60%"></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </template>
                </div>
            </div>

            <!-- ── DONE Column ── -->
            <div class="space-y-4">
                <div class="flex items-center gap-3 px-1 mb-2">
                    <div class="w-2.5 h-2.5 rounded-full bg-emerald-500 shadow-[0_0_6px_rgba(16,185,129,0.5)]"></div>
                    <h2 class="text-sm font-bold uppercase tracking-widest text-emerald-400">Done</h2>
                    <span class="ml-auto text-xs font-semibold text-emerald-400 bg-emerald-500/10 px-2.5 py-1 rounded-full border border-emerald-500/20" x-text="doneCount"></span>
                </div>
                <div class="kanban-col space-y-3 overflow-y-auto pr-1" style="max-height: 65vh;">
                    <template x-if="doneItems.length === 0">
                        <div class="flex flex-col items-center justify-center py-16 text-slate-600">
                            <svg class="w-10 h-10 mb-3 opacity-20" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            <p class="text-sm font-medium">No completed tasks yet</p>
                        </div>
                    </template>
                    <template x-for="(item, i) in doneItems" :key="'d'+i">
                        <div class="card-glass rounded-xl border border-emerald-500/10 p-4 transition-all duration-300 hover:border-emerald-500/20 group">
                            <div class="flex items-start gap-3">
                                <div class="mt-0.5 flex-shrink-0">
                                    <div class="w-5 h-5 rounded-full bg-emerald-500/20 flex items-center justify-center border border-emerald-500/30">
                                        <svg class="w-3 h-3 text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"/></svg>
                                    </div>
                                </div>
                                <div>
                                    <p class="text-sm text-emerald-200/50 line-through leading-relaxed" x-text="item.text"></p>
                                    <template x-if="item.section">
                                        <span class="inline-block mt-2 text-[10px] font-semibold uppercase tracking-wider text-emerald-600/50 bg-emerald-500/5 px-2 py-0.5 rounded" x-text="item.section"></span>
                                    </template>
                                </div>
                            </div>
                        </div>
                    </template>
                </div>
            </div>
        </div>
    </div>

    <script>
        document.addEventListener('alpine:init', () => {
            Alpine.data('kanban', () => ({
                allTasks: [],
                isPolling: true,
                startTime: Date.now(),
                elapsed: '00:00',
                totalCount: 0,
                doneCount: 0,
                activeCount: 0,
                queuedCount: 0,
                progressPercentage: 0,

                get queuedItems()  { return this.allTasks.filter(t => t.status === 'pending'); },
                get activeItems()  { return this.allTasks.filter(t => t.status === 'in-progress'); },
                get doneItems()    { return this.allTasks.filter(t => t.status === 'completed'); },

                updateElapsed() {
                    const diff = Math.floor((Date.now() - this.startTime) / 1000);
                    const m = String(Math.floor(diff / 60)).padStart(2, '0');
                    const s = String(diff % 60).padStart(2, '0');
                    this.elapsed = m + ':' + s;
                },

                async fetchProgress() {
                    try {
                        const res = await fetch('/api/progress');
                        const data = await res.json();

                        if (JSON.stringify(this.allTasks) !== JSON.stringify(data.tasks)) {
                            this.allTasks = data.tasks;
                        }

                        this.totalCount   = this.allTasks.length;
                        this.doneCount    = this.doneItems.length;
                        this.activeCount  = this.activeItems.length;
                        this.queuedCount  = this.queuedItems.length;
                        this.progressPercentage = this.totalCount > 0 ? Math.round((this.doneCount / this.totalCount) * 100) : 0;

                        if (data.isComplete && this.totalCount > 0) {
                            this.isPolling = false;
                        }
                    } catch (e) { }
                },

                startPolling() {
                    this.fetchProgress();
                    this.updateElapsed();
                    const dataInterval = setInterval(() => {
                        if (!this.isPolling) { clearInterval(dataInterval); return; }
                        this.fetchProgress();
                    }, 1000);
                    // Timer runs independently
                    setInterval(() => this.updateElapsed(), 1000);
                }
            }));
        });
    </script>
</body>
</html>`;

// ═══════════ SERVER ═══════════
const server = http.createServer((req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');

    if (req.url === '/') {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(HTML);
        return;
    }

    if (req.url === '/api/progress') {
        const session = getLatestSession();
        if (!session) {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ tasks: [], isComplete: false }));
            return;
        }

        try {
            const content = fs.readFileSync(session.taskPath, 'utf8');
            const lines = content.split('\\n');
            const tasks = [];
            let currentSection = null;
            let inProgressCount = 0;
            let pendingCount = 0;

            for (const line of lines) {
                const trimmed = line.trim();

                // Detect section headers
                if (trimmed.startsWith('#')) {
                    currentSection = trimmed.replace(/#/g, '').trim();
                    continue;
                }

                // Match checkbox items
                const match = trimmed.match(/^(?:-|\\*)?\\s*\\[([ x\\/])\\]\\s+(.*)/i);
                if (match) {
                    const ch = match[1].toLowerCase();
                    const text = match[2];
                    let status = 'pending';
                    if (ch === 'x') status = 'completed';
                    else if (ch === '/') { status = 'in-progress'; inProgressCount++; }
                    else { pendingCount++; }

                    tasks.push({ status, text, section: currentSection });
                }
            }

            const hasTasks = tasks.length > 0;
            const isComplete = hasTasks && inProgressCount === 0 && pendingCount === 0;

            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ tasks, isComplete }));
        } catch (e) {
            res.writeHead(500);
            res.end(JSON.stringify({ error: e.message }));
        }
        return;
    }

    res.writeHead(404);
    res.end();
});

server.listen(PORT, '127.0.0.1', () => {
    const url = `http://127.0.0.1:${PORT}`;
    console.log(`[Agent Kanban] Dashboard live at ${url}`);
    console.log(`[Agent Kanban] Monitoring: ${BRAIN_DIR}`);
    try { require('child_process').exec(`start ${url}`); } catch (e) { }
});
