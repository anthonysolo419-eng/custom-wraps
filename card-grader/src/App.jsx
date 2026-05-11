import { useState, useCallback, useRef, useEffect } from 'react'

const MODEL = 'claude-sonnet-4-6'

const SYSTEM_PROMPT = `You are a world-class professional trading card grader with decades of experience grading for PSA, BGS, and SGC. Analyze the provided card image(s) with expert precision.

Evaluate each of the following 5 categories on a 1–10 scale (decimals allowed, e.g. 8.5):
1. CENTERING — Border width ratios on all sides (left/right, top/bottom). Perfect centering = 10.
2. CORNERS — Sharpness and condition of all four corners. Razor sharp = 10.
3. EDGES — Condition of all four edges. No nicks, chips, or roughness = 10.
4. SURFACE — Condition of card faces/backs. No scratches, stains, print lines, or indentations = 10.
5. PRINT QUALITY — Color saturation, focus, registration, print defects. Factory perfect = 10.

Then calculate an OVERALL PSA-style numeric grade (1–10 integer or .5 step) using this rubric:
- 10 GEM MINT: All categories 9.5+, virtually perfect
- 9 MINT: Minor flaws in at most one category, all others 9+
- 8 NM-MT: Slight imperfections in 1-2 categories
- 7 NM: Noticeable but minor flaws
- 6 EX-MT: Moderate wear in multiple areas
- 5 EX: Heavy wear but card still presentable
- 4 VG-EX: Obvious wear throughout
- 3 VG: Heavy play wear
- 2 GOOD: Heavily worn/damaged
- 1 POOR: Completely destroyed

IMPORTANT: For each issue, you must specify its location using ONLY one of these exact zone names:
"top-left-corner", "top-right-corner", "bottom-left-corner", "bottom-right-corner",
"top-edge", "bottom-edge", "left-edge", "right-edge", "center"

Return ONLY a valid JSON object with no markdown, no explanation, no extra text:
{
  "centering": {
    "score": <number 1-10>,
    "label": "<e.g. 'Excellent' | 'Near Mint' | 'Gem Mint'>",
    "explanation": "<1-2 sentence expert analysis>",
    "issues": [
      { "description": "<specific issue>", "zone": "<zone name from list above>" }
    ]
  },
  "corners": {
    "score": <number 1-10>,
    "label": "<label>",
    "explanation": "<analysis>",
    "issues": [
      { "description": "<specific issue>", "zone": "<zone name>" }
    ]
  },
  "edges": {
    "score": <number 1-10>,
    "label": "<label>",
    "explanation": "<analysis>",
    "issues": [
      { "description": "<specific issue>", "zone": "<zone name>" }
    ]
  },
  "surface": {
    "score": <number 1-10>,
    "label": "<label>",
    "explanation": "<analysis>",
    "issues": [
      { "description": "<specific issue>", "zone": "<zone name>" }
    ]
  },
  "printQuality": {
    "score": <number 1-10>,
    "label": "<label>",
    "explanation": "<analysis>",
    "issues": [
      { "description": "<specific issue>", "zone": "<zone name>" }
    ]
  },
  "overall": {
    "numericGrade": <number>,
    "psaLabel": "<e.g. 'GEM MINT 10' | 'NM-MT 8'>",
    "summary": "<2-3 sentence overall assessment>",
    "gradeHurting": ["<factor hurting the grade>"],
    "submissionTips": ["<actionable tip>"]
  }
}`

const CATEGORY_CONFIG = {
  centering: { label: 'Centering', description: 'Border ratios & alignment', icon: '⊞' },
  corners: { label: 'Corners', description: 'Sharpness of all 4 corners', icon: '◇' },
  edges: { label: 'Edges', description: 'Condition of all 4 edges', icon: '▭' },
  surface: { label: 'Surface', description: 'Card face & back condition', icon: '◈' },
  printQuality: { label: 'Print Quality', description: 'Color, focus & registration', icon: '◉' },
}

const CATEGORY_COLORS = {
  centering: '#3b82f6',
  corners: '#f59e0b',
  edges: '#22c55e',
  surface: '#ef4444',
  printQuality: '#a855f7',
}

const PSA_GRADES = {
  10: { label: 'GEM MINT', color: '#f59e0b', bg: 'from-amber-500/20 to-yellow-600/10' },
  9: { label: 'MINT', color: '#22c55e', bg: 'from-green-500/20 to-emerald-600/10' },
  8: { label: 'NM-MT', color: '#3b82f6', bg: 'from-blue-500/20 to-sky-600/10' },
  7: { label: 'NM', color: '#8b5cf6', bg: 'from-violet-500/20 to-purple-600/10' },
  6: { label: 'EX-MT', color: '#6366f1', bg: 'from-indigo-500/20 to-blue-600/10' },
  5: { label: 'EX', color: '#eab308', bg: 'from-yellow-500/20 to-amber-600/10' },
  4: { label: 'VG-EX', color: '#f97316', bg: 'from-orange-500/20 to-amber-600/10' },
  3: { label: 'VG', color: '#ef4444', bg: 'from-red-500/20 to-rose-600/10' },
  2: { label: 'GOOD', color: '#dc2626', bg: 'from-red-600/20 to-red-800/10' },
  1: { label: 'POOR', color: '#9f1239', bg: 'from-rose-900/20 to-red-950/10' },
}

function getScoreColor(s) {
  if (s >= 9) return '#f59e0b'
  if (s >= 7) return '#22c55e'
  if (s >= 5) return '#eab308'
  if (s >= 3) return '#f97316'
  return '#ef4444'
}

function getScoreTextClass(s) {
  if (s >= 9) return 'text-amber-400'
  if (s >= 7) return 'text-green-400'
  if (s >= 5) return 'text-yellow-400'
  if (s >= 3) return 'text-orange-400'
  return 'text-red-400'
}

function fileToBase64(file) {
  return new Promise((resolve) => {
    const reader = new FileReader()
    reader.onload = (e) => resolve(e.target.result.split(',')[1])
    reader.readAsDataURL(file)
  })
}

function getIssueDescription(issue) {
  if (typeof issue === 'string') return issue
  return issue.description || ''
}

function ScoreRing({ score, size = 88 }) {
  const r = size * 0.41
  const c = 2 * Math.PI * r
  const fill = (score / 10) * c
  const color = getScoreColor(score)
  const cx = size / 2
  const cy = size / 2

  return (
    <div className="relative" style={{ width: size, height: size }}>
      <svg width={size} height={size} className="transform -rotate-90">
        <circle cx={cx} cy={cy} r={r} fill="none" stroke="rgba(255,255,255,0.07)" strokeWidth="5" />
        <circle
          cx={cx} cy={cy} r={r}
          fill="none"
          stroke={color}
          strokeWidth="5"
          strokeDasharray={`${fill} ${c}`}
          strokeLinecap="round"
          style={{ transition: 'stroke-dasharray 0.8s cubic-bezier(0.4,0,0.2,1)' }}
        />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <span className={`font-black leading-none ${getScoreTextClass(score)}`} style={{ fontSize: size * 0.26 }}>
          {score % 1 === 0 ? score.toFixed(0) : score.toFixed(1)}
        </span>
        <span className="text-zinc-500 font-medium" style={{ fontSize: size * 0.12 }}>/ 10</span>
      </div>
    </div>
  )
}

const ZONE_COORDS = {
  'top-left-corner':     { x: 0.08, y: 0.08 },
  'top-right-corner':    { x: 0.92, y: 0.08 },
  'bottom-left-corner':  { x: 0.08, y: 0.92 },
  'bottom-right-corner': { x: 0.92, y: 0.92 },
  'top-edge':            { x: 0.50, y: 0.04 },
  'bottom-edge':         { x: 0.50, y: 0.96 },
  'left-edge':           { x: 0.04, y: 0.50 },
  'right-edge':          { x: 0.96, y: 0.50 },
  'center':              { x: 0.50, y: 0.50 },
}

function AnnotatedImage({ imageFile, report, selectedCategory, onSelectCategory }) {
  const [tooltip, setTooltip] = useState(null)

  const allMarkers = []
  Object.keys(CATEGORY_CONFIG).forEach((cat) => {
    const issues = report[cat]?.issues || []
    issues.forEach((issue, i) => {
      if (!issue || typeof issue !== 'object') return
      const zone = issue.zone || 'center'
      const coords = ZONE_COORDS[zone] || ZONE_COORDS['center']
      // Offset overlapping markers in the same zone slightly
      const siblings = allMarkers.filter((m) => m.zone === zone)
      const offset = siblings.length * 0.04
      allMarkers.push({
        description: issue.description,
        zone,
        x: Math.min(0.95, coords.x + offset),
        y: Math.min(0.95, coords.y + offset),
        category: cat,
        color: CATEGORY_COLORS[cat],
        id: `${cat}-${i}`,
      })
    })
  })

  const visibleMarkers = selectedCategory
    ? allMarkers.filter((m) => m.category === selectedCategory)
    : allMarkers

  return (
    <div className="space-y-3">
      {/* Category filter pills */}
      <div className="flex flex-wrap gap-2">
        <button
          onClick={() => onSelectCategory(null)}
          className={`px-3 py-1 rounded-full text-xs font-semibold border transition-all ${
            selectedCategory === null
              ? 'bg-zinc-200 text-zinc-900 border-zinc-200'
              : 'bg-transparent text-zinc-400 border-zinc-700 hover:border-zinc-500'
          }`}
        >
          All Flaws
        </button>
        {Object.keys(CATEGORY_CONFIG).map((cat) => {
          const count = allMarkers.filter((m) => m.category === cat).length
          if (count === 0) return null
          return (
            <button
              key={cat}
              onClick={() => onSelectCategory(selectedCategory === cat ? null : cat)}
              className="px-3 py-1 rounded-full text-xs font-semibold border transition-all"
              style={{
                backgroundColor: selectedCategory === cat ? CATEGORY_COLORS[cat] : 'transparent',
                color: selectedCategory === cat ? '#000' : CATEGORY_COLORS[cat],
                borderColor: CATEGORY_COLORS[cat],
              }}
            >
              {CATEGORY_CONFIG[cat].label} ({count})
            </button>
          )
        })}
      </div>

      {/* Annotated image */}
      <div className="relative w-full rounded-xl overflow-hidden border border-zinc-800">
        <img
          src={URL.createObjectURL(imageFile)}
          alt="Card front"
          className="w-full object-contain rounded-xl"
          style={{ maxHeight: '480px', objectFit: 'contain', background: '#18181b' }}
        />

        {visibleMarkers.map((marker) => (
          <div
            key={marker.id}
            className="absolute"
            style={{
              left: `${marker.x * 100}%`,
              top: `${marker.y * 100}%`,
              transform: 'translate(-50%, -50%)',
              zIndex: 10,
            }}
            onMouseEnter={() => setTooltip(marker)}
            onMouseLeave={() => setTooltip(null)}
          >
            <div
              className="absolute rounded-full animate-ping opacity-50"
              style={{ backgroundColor: marker.color, width: 20, height: 20, top: -2, left: -2 }}
            />
            <div
              className="relative w-4 h-4 rounded-full border-2 border-white cursor-pointer shadow-lg"
              style={{ backgroundColor: marker.color, boxShadow: `0 0 8px ${marker.color}` }}
            />
            {tooltip?.id === marker.id && (
              <div
                className="absolute z-20 w-44 pointer-events-none"
                style={{ bottom: '120%', left: '50%', transform: 'translateX(-50%)' }}
              >
                <div className="bg-zinc-900 border border-zinc-700 rounded-lg p-2.5 shadow-2xl text-xs">
                  <div className="font-bold mb-1" style={{ color: marker.color }}>
                    {CATEGORY_CONFIG[marker.category].label} — {marker.zone.replace(/-/g, ' ')}
                  </div>
                  <div className="text-zinc-300 leading-relaxed">{marker.description}</div>
                </div>
              </div>
            )}
          </div>
        ))}

        {allMarkers.length === 0 && (
          <div className="absolute inset-0 flex items-end justify-center pb-3 pointer-events-none">
            <span className="bg-zinc-900/80 text-zinc-400 text-xs px-3 py-1 rounded-full">
              No flaws detected
            </span>
          </div>
        )}
      </div>

      <p className="text-zinc-600 text-xs">Hover a marker to see the flaw · Click a category pill to filter</p>
    </div>
  )
}

function CategoryCard({ categoryKey, data, isHighlighted, onClick }) {
  const [expanded, setExpanded] = useState(false)
  const cfg = CATEGORY_CONFIG[categoryKey]
  const color = CATEGORY_COLORS[categoryKey]

  return (
    <div
      className="bg-zinc-900 border rounded-xl overflow-hidden cursor-pointer transition-all"
      style={{ borderColor: isHighlighted ? color : 'rgb(39,39,42)' }}
      onClick={() => {
        setExpanded((e) => !e)
        onClick()
      }}
    >
      <div className="p-4 flex items-center gap-4">
        <ScoreRing score={data.score} size={72} />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-0.5">
            <span className="text-zinc-400 text-xs">{cfg.icon}</span>
            <span className="font-bold text-zinc-100 text-sm uppercase tracking-wider">{cfg.label}</span>
            {isHighlighted && (
              <span className="text-xs px-1.5 py-0.5 rounded font-semibold" style={{ background: `${color}20`, color }}>
                Showing on image
              </span>
            )}
          </div>
          <p className="text-zinc-500 text-xs mb-1">{cfg.description}</p>
          <span
            className="inline-block px-2 py-0.5 rounded-full text-xs font-semibold"
            style={{ backgroundColor: `${getScoreColor(data.score)}20`, color: getScoreColor(data.score) }}
          >
            {data.label}
          </span>
        </div>
        <div className="text-zinc-600 text-xs select-none">{expanded ? '▲' : '▼'}</div>
      </div>

      {expanded && (
        <div className="border-t border-zinc-800 px-4 pb-4 pt-3 space-y-3">
          <p className="text-zinc-300 text-sm leading-relaxed">{data.explanation}</p>
          {data.issues && data.issues.length > 0 ? (
            <div>
              <p className="text-zinc-500 text-xs uppercase tracking-wider mb-2 font-semibold">Issues Detected</p>
              <ul className="space-y-1">
                {data.issues.map((issue, i) => (
                  <li key={i} className="flex items-start gap-2 text-sm text-zinc-400">
                    <span className="mt-0.5 flex-shrink-0" style={{ color }}>✕</span>
                    {getIssueDescription(issue)}
                  </li>
                ))}
              </ul>
            </div>
          ) : (
            <div className="flex items-center gap-2 text-sm text-green-400">
              <span>✓</span>
              <span>No issues detected in this category</span>
            </div>
          )}
        </div>
      )}
    </div>
  )
}

function OverallGrade({ overall }) {
  const grade = overall.numericGrade
  const gradeInfo = PSA_GRADES[Math.round(grade)] || PSA_GRADES[1]

  return (
    <div className={`rounded-2xl border p-6 bg-gradient-to-br ${gradeInfo.bg} border-zinc-800`}>
      <div className="flex flex-col sm:flex-row items-center gap-6">
        <div className="flex-shrink-0 text-center">
          <div
            className="w-28 h-28 rounded-2xl flex flex-col items-center justify-center font-black border-2"
            style={{
              borderColor: gradeInfo.color,
              boxShadow: `0 0 24px ${gradeInfo.color}40`,
              background: `${gradeInfo.color}12`,
            }}
          >
            <span className="text-5xl leading-none" style={{ color: gradeInfo.color }}>{grade}</span>
            <span className="text-xs font-bold text-zinc-400 mt-0.5 tracking-wider">GRADE</span>
          </div>
          <p className="mt-2 font-black text-sm tracking-widest" style={{ color: gradeInfo.color }}>
            {overall.psaLabel}
          </p>
        </div>
        <div className="flex-1">
          <p className="text-zinc-200 text-sm leading-relaxed">{overall.summary}</p>
        </div>
      </div>

      {overall.gradeHurting && overall.gradeHurting.length > 0 && (
        <div className="mt-5 pt-5 border-t border-zinc-800">
          <p className="text-xs uppercase tracking-wider font-semibold text-zinc-500 mb-3">What's Hurting Your Grade</p>
          <div className="flex flex-wrap gap-2">
            {overall.gradeHurting.map((factor, i) => (
              <span key={i} className="px-3 py-1 rounded-full text-xs font-medium bg-red-500/10 text-red-400 border border-red-500/20">
                {factor}
              </span>
            ))}
          </div>
        </div>
      )}

      {overall.submissionTips && overall.submissionTips.length > 0 && (
        <div className="mt-5 pt-5 border-t border-zinc-800">
          <p className="text-xs uppercase tracking-wider font-semibold text-zinc-500 mb-3">Submission Tips</p>
          <ul className="space-y-2">
            {overall.submissionTips.map((tip, i) => (
              <li key={i} className="flex items-start gap-2 text-sm text-zinc-300">
                <span className="text-amber-400 mt-0.5 flex-shrink-0">→</span>
                {tip}
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  )
}

function CameraModal({ onCapture, onClose }) {
  const videoRef = useRef(null)
  const streamRef = useRef(null)
  const [error, setError] = useState(null)
  const [capturing, setCapturing] = useState(false)

  useEffect(() => {
    navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' }, audio: false })
      .then((stream) => {
        streamRef.current = stream
        if (videoRef.current) videoRef.current.srcObject = stream
      })
      .catch(() => setError('Camera access denied. Use the upload button instead.'))
    return () => streamRef.current?.getTracks().forEach((t) => t.stop())
  }, [])

  const capture = () => {
    setCapturing(true)
    const video = videoRef.current
    const canvas = document.createElement('canvas')
    canvas.width = video.videoWidth
    canvas.height = video.videoHeight
    canvas.getContext('2d').drawImage(video, 0, 0)
    canvas.toBlob((blob) => {
      const file = new File([blob], `card-${Date.now()}.jpg`, { type: 'image/jpeg' })
      streamRef.current?.getTracks().forEach((t) => t.stop())
      onCapture(file)
    }, 'image/jpeg', 0.95)
  }

  return (
    <div className="fixed inset-0 z-50 bg-black flex flex-col">
      <div className="flex items-center justify-between px-4 py-3 bg-zinc-900 border-b border-zinc-800">
        <span className="font-bold text-zinc-100">Take Photo</span>
        <button onClick={onClose} className="text-zinc-400 hover:text-zinc-100 text-2xl leading-none">✕</button>
      </div>
      <div className="flex-1 relative overflow-hidden bg-black">
        {error ? (
          <div className="absolute inset-0 flex items-center justify-center text-zinc-400 text-sm px-8 text-center">{error}</div>
        ) : (
          <video ref={videoRef} autoPlay playsInline className="w-full h-full object-cover" />
        )}
        {/* Card outline guide */}
        <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
          <div className="border-2 border-amber-400/70 rounded-lg" style={{ width: '65%', aspectRatio: '2.5/3.5' }} />
        </div>
      </div>
      <div className="px-4 py-5 bg-zinc-900 border-t border-zinc-800 flex flex-col items-center gap-2">
        <p className="text-zinc-500 text-xs mb-1">Align card within the guide</p>
        <button
          onClick={capture}
          disabled={!!error || capturing}
          className="w-16 h-16 rounded-full border-4 border-white flex items-center justify-center disabled:opacity-40"
          style={{ background: 'linear-gradient(135deg, #f59e0b, #d97706)' }}
        >
          <span className="text-2xl">📷</span>
        </button>
      </div>
    </div>
  )
}

function generateGradeCard(report, cardName) {
  return new Promise((resolve) => {
    const W = 480, H = 640
    const canvas = document.createElement('canvas')
    canvas.width = W
    canvas.height = H
    const ctx = canvas.getContext('2d')

    // Background
    const bg = ctx.createLinearGradient(0, 0, W, H)
    bg.addColorStop(0, '#09090b')
    bg.addColorStop(1, '#18181b')
    ctx.fillStyle = bg
    ctx.fillRect(0, 0, W, H)

    // Gold top bar
    const gold = ctx.createLinearGradient(0, 0, W, 0)
    gold.addColorStop(0, '#d97706')
    gold.addColorStop(0.5, '#f59e0b')
    gold.addColorStop(1, '#d97706')
    ctx.fillStyle = gold
    ctx.fillRect(0, 0, W, 56)

    // Header text
    ctx.fillStyle = '#000'
    ctx.font = 'bold 22px Inter, system-ui, sans-serif'
    ctx.textAlign = 'center'
    ctx.fillText('CardScore AI', W / 2, 36)

    // Tagline
    ctx.fillStyle = 'rgba(0,0,0,0.6)'
    ctx.font = '11px Inter, system-ui, sans-serif'
    ctx.fillText('AI-POWERED PRE-GRADE REPORT', W / 2, 50)

    // Card name
    ctx.fillStyle = '#a1a1aa'
    ctx.font = '13px Inter, system-ui, sans-serif'
    ctx.textAlign = 'center'
    ctx.fillText(cardName || 'Trading Card', W / 2, 88)

    // Grade circle
    const grade = report.overall.numericGrade
    const gradeColor = grade >= 9 ? '#f59e0b' : grade >= 7 ? '#22c55e' : grade >= 5 ? '#eab308' : grade >= 3 ? '#f97316' : '#ef4444'
    ctx.beginPath()
    ctx.arc(W / 2, 170, 72, 0, Math.PI * 2)
    ctx.fillStyle = `${gradeColor}18`
    ctx.fill()
    ctx.strokeStyle = gradeColor
    ctx.lineWidth = 4
    ctx.stroke()

    // Progress arc
    const r = 72, c2 = 2 * Math.PI * r
    ctx.beginPath()
    ctx.arc(W / 2, 170, r, -Math.PI / 2, -Math.PI / 2 + (grade / 10) * Math.PI * 2)
    ctx.strokeStyle = gradeColor
    ctx.lineWidth = 6
    ctx.lineCap = 'round'
    ctx.stroke()

    // Grade number
    ctx.fillStyle = gradeColor
    ctx.font = 'bold 64px Inter, system-ui, sans-serif'
    ctx.textAlign = 'center'
    ctx.textBaseline = 'middle'
    ctx.fillText(grade % 1 === 0 ? grade.toFixed(0) : grade.toFixed(1), W / 2, 170)

    // PSA label
    ctx.textBaseline = 'alphabetic'
    ctx.fillStyle = gradeColor
    ctx.font = 'bold 16px Inter, system-ui, sans-serif'
    ctx.fillText(report.overall.psaLabel, W / 2, 264)

    // Divider
    ctx.strokeStyle = '#3f3f46'
    ctx.lineWidth = 1
    ctx.beginPath()
    ctx.moveTo(32, 286)
    ctx.lineTo(W - 32, 286)
    ctx.stroke()

    // Category scores
    const cats = [
      ['Centering', report.centering?.score],
      ['Corners', report.corners?.score],
      ['Edges', report.edges?.score],
      ['Surface', report.surface?.score],
      ['Print Quality', report.printQuality?.score],
    ]
    const colW = (W - 64) / 2
    cats.forEach(([label, score], i) => {
      const col = i % 2
      const row = Math.floor(i / 2)
      const x = 40 + col * (colW + 16)
      const y = 310 + row * 58
      const sc = score || 0
      const sc_color = sc >= 9 ? '#f59e0b' : sc >= 7 ? '#22c55e' : sc >= 5 ? '#eab308' : sc >= 3 ? '#f97316' : '#ef4444'

      // Card bg
      ctx.fillStyle = '#27272a'
      ctx.beginPath()
      ctx.roundRect(x, y, colW, 46, 8)
      ctx.fill()

      // Score bar
      ctx.fillStyle = `${sc_color}30`
      ctx.beginPath()
      ctx.roundRect(x, y, colW * (sc / 10), 46, 8)
      ctx.fill()

      ctx.fillStyle = '#a1a1aa'
      ctx.font = '11px Inter, system-ui, sans-serif'
      ctx.textAlign = 'left'
      ctx.textBaseline = 'alphabetic'
      ctx.fillText(label.toUpperCase(), x + 10, y + 18)

      ctx.fillStyle = sc_color
      ctx.font = 'bold 18px Inter, system-ui, sans-serif'
      ctx.fillText(sc % 1 === 0 ? sc.toFixed(0) : sc.toFixed(1), x + 10, y + 37)
    })

    // Footer
    ctx.strokeStyle = '#3f3f46'
    ctx.lineWidth = 1
    ctx.beginPath()
    ctx.moveTo(32, 550)
    ctx.lineTo(W - 32, 550)
    ctx.stroke()

    ctx.fillStyle = '#52525b'
    ctx.font = '11px Inter, system-ui, sans-serif'
    ctx.textAlign = 'center'
    ctx.fillText(`AI Pre-Grade · ${new Date().toLocaleDateString()} · cardscore.ai`, W / 2, 574)
    ctx.fillStyle = '#3f3f46'
    ctx.fillText('For reference only — not an official PSA/BGS grade', W / 2, 592)

    resolve(canvas.toDataURL('image/png'))
  })
}

function copyListingText(report, cardName) {
  const cats = [
    ['Centering', report.centering?.score],
    ['Corners', report.corners?.score],
    ['Edges', report.edges?.score],
    ['Surface', report.surface?.score],
    ['Print Quality', report.printQuality?.score],
  ]
  const lines = [
    `🏆 CardScore AI Pre-Grade Report`,
    `━━━━━━━━━━━━━━━━━━━━━━`,
    cardName ? `Card: ${cardName}` : null,
    `Overall Grade: ${report.overall.psaLabel}`,
    `━━━━━━━━━━━━━━━━━━━━━━`,
    ...cats.map(([l, s]) => `${l}: ${s % 1 === 0 ? s.toFixed(0) : s.toFixed(1)}/10`),
    `━━━━━━━━━━━━━━━━━━━━━━`,
    report.overall.summary,
    ``,
    `Graded by CardScore AI — AI-powered pre-grade tool`,
    `(This is an AI estimate, not an official PSA/BGS/SGC grade)`,
  ].filter(Boolean)
  navigator.clipboard.writeText(lines.join('\n'))
}

export default function App() {
  const [images, setImages] = useState([])
  const [apiKey, setApiKey] = useState(import.meta.env.VITE_ANTHROPIC_API_KEY || '')
  const [showKeyInput, setShowKeyInput] = useState(!import.meta.env.VITE_ANTHROPIC_API_KEY)
  const [isDragging, setIsDragging] = useState(false)
  const [loading, setLoading] = useState(false)
  const [loadingStep, setLoadingStep] = useState('')
  const [report, setReport] = useState(null)
  const [error, setError] = useState(null)
  const [selectedCategory, setSelectedCategory] = useState(null)
  const [showCamera, setShowCamera] = useState(false)
  const [cardName, setCardName] = useState('')
  const [copied, setCopied] = useState(false)
  const fileInputRef = useRef(null)
  const cameraInputRef = useRef(null)

  const addImages = useCallback((files) => {
    const imageFiles = Array.from(files)
      .filter((f) => f.type.startsWith('image/'))
      .slice(0, 2 - images.length)
    if (imageFiles.length === 0) return
    setImages((prev) => [...prev, ...imageFiles].slice(0, 2))
    setReport(null)
    setError(null)
  }, [images.length])

  const removeImage = (idx) => {
    setImages((prev) => prev.filter((_, i) => i !== idx))
    setReport(null)
  }

  const handleDrop = useCallback((e) => {
    e.preventDefault()
    setIsDragging(false)
    addImages(e.dataTransfer.files)
  }, [addImages])

  const handleDragOver = (e) => { e.preventDefault(); setIsDragging(true) }
  const handleDragLeave = () => setIsDragging(false)
  const handleFileInput = (e) => { addImages(e.target.files); e.target.value = '' }

  const gradeCard = async () => {
    if (images.length === 0) return
    if (!apiKey.trim()) { setError('Please enter your Anthropic API key.'); return }

    setLoading(true)
    setError(null)
    setReport(null)
    setSelectedCategory(null)
    setShowCamera(false)

    try {
      setLoadingStep('Encoding images…')
      const imageBlocks = await Promise.all(
        images.map(async (file, i) => {
          const b64 = await fileToBase64(file)
          const mediaType = file.type || 'image/jpeg'
          return [
            { type: 'text', text: i === 0 ? 'Card front image:' : 'Card back image:' },
            { type: 'image', source: { type: 'base64', media_type: mediaType, data: b64 } },
          ]
        })
      )

      setLoadingStep('Analyzing with Claude Vision…')
      const res = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey.trim(),
          'anthropic-version': '2023-06-01',
          'anthropic-dangerous-direct-browser-access': 'true',
        },
        body: JSON.stringify({
          model: MODEL,
          max_tokens: 2048,
          system: SYSTEM_PROMPT,
          messages: [{
            role: 'user',
            content: [
              ...imageBlocks.flat(),
              { type: 'text', text: 'Please grade this trading card and return the JSON analysis with exact flaw locations.' },
            ],
          }],
        }),
      })

      if (!res.ok) {
        const body = await res.json().catch(() => ({}))
        throw new Error(body?.error?.message || `API error ${res.status}`)
      }

      setLoadingStep('Parsing grade report…')
      const data = await res.json()
      const text = data.content?.[0]?.text || ''

      let parsed
      try {
        parsed = JSON.parse(text)
      } catch {
        const mdMatch = text.match(/```(?:json)?\s*([\s\S]*?)\s*```/)
        if (mdMatch) {
          parsed = JSON.parse(mdMatch[1])
        } else {
          const objMatch = text.match(/\{[\s\S]*\}/)
          if (!objMatch) throw new Error('Could not extract JSON from response')
          parsed = JSON.parse(objMatch[0])
        }
      }

      setReport(parsed)
    } catch (err) {
      setError(err.message || 'An unexpected error occurred.')
    } finally {
      setLoading(false)
      setLoadingStep('')
    }
  }

  const avgScore = report
    ? (
        ['centering', 'corners', 'edges', 'surface', 'printQuality']
          .map((k) => report[k]?.score)
          .filter(Boolean)
          .reduce((a, b) => a + b, 0) /
        ['centering', 'corners', 'edges', 'surface', 'printQuality']
          .map((k) => report[k]?.score)
          .filter(Boolean).length
      ).toFixed(1)
    : null

  const handleCategoryClick = (cat) => {
    setSelectedCategory((prev) => (prev === cat ? null : cat))
  }

  return (
    <>
    {showCamera && (
      <CameraModal
        onCapture={(file) => { addImages([file]); setShowCamera(false) }}
        onClose={() => setShowCamera(false)}
      />
    )}
    <div className="min-h-screen bg-zinc-950" style={{ fontFamily: 'Inter, system-ui, sans-serif' }}>
      {/* Header */}
      <header className="border-b border-zinc-800/60 bg-zinc-950/80 backdrop-blur sticky top-0 z-10">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg flex items-center justify-center text-sm font-black"
              style={{ background: 'linear-gradient(135deg, #f59e0b, #d97706)' }}>
              V
            </div>
            <div>
              <span className="font-black text-zinc-100 tracking-tight">CardScore</span>
              <span className="text-amber-500 text-xs ml-1.5 font-semibold uppercase tracking-widest">AI</span>
            </div>
          </div>
          <div className="flex items-center gap-2 text-xs text-zinc-500">
            <span className="w-1.5 h-1.5 rounded-full" style={{ background: '#f59e0b', boxShadow: '0 0 4px #f59e0b' }} />
            Powered by Claude Vision
          </div>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-4 py-8 space-y-6">
        {/* Hero */}
        <div className="text-center pt-4 pb-2">
          <h1 className="text-3xl sm:text-4xl font-black text-zinc-100 leading-tight mb-2">
            Professional Card{' '}
            <span style={{ background: 'linear-gradient(135deg, #f59e0b, #d97706, #fbbf24)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
              Grading
            </span>
          </h1>
          <p className="text-zinc-400 text-sm max-w-md mx-auto">
            Upload a card photo. Claude Vision grades it and pins every flaw directly on the image.
          </p>
        </div>

        {/* API Key */}
        {showKeyInput && (
          <div className="bg-zinc-900 border border-amber-500/30 rounded-xl p-4">
            <div className="flex items-center gap-2 mb-3">
              <span className="text-amber-400 text-sm">🔑</span>
              <span className="text-sm font-semibold text-zinc-200">Anthropic API Key</span>
              <span className="text-xs text-zinc-500 ml-auto">
                Or set <code className="text-amber-400">VITE_ANTHROPIC_API_KEY</code> in .env
              </span>
            </div>
            <div className="flex gap-2">
              <input
                type="password"
                value={apiKey}
                onChange={(e) => setApiKey(e.target.value)}
                placeholder="sk-ant-…"
                className="flex-1 bg-zinc-800 border border-zinc-700 rounded-lg px-3 py-2 text-sm text-zinc-100 placeholder-zinc-600 focus:outline-none focus:border-amber-500/60"
              />
              <button
                onClick={() => setShowKeyInput(false)}
                disabled={!apiKey.trim()}
                className="px-4 py-2 rounded-lg text-sm font-semibold transition-all disabled:opacity-40"
                style={{ background: 'linear-gradient(135deg, #f59e0b, #d97706)', color: '#000' }}
              >
                Save
              </button>
            </div>
          </div>
        )}
        {!showKeyInput && (
          <button onClick={() => setShowKeyInput(true)} className="text-xs text-zinc-600 hover:text-zinc-400 transition-colors">
            Change API key
          </button>
        )}

        {/* Card name */}
        <div className="flex gap-2 items-center">
          <input
            type="text"
            value={cardName}
            onChange={(e) => setCardName(e.target.value)}
            placeholder="Card name (optional — e.g. 2003 Topps LeBron James RC #221)"
            className="flex-1 bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-sm text-zinc-100 placeholder-zinc-600 focus:outline-none focus:border-zinc-600"
          />
        </div>

        {/* Upload Zone */}
        <div
          onDrop={handleDrop}
          onDragOver={handleDragOver}
          onDragLeave={handleDragLeave}
          onClick={() => images.length < 2 && fileInputRef.current?.click()}
          className={`rounded-2xl border-2 border-dashed p-8 text-center transition-all cursor-pointer ${
            isDragging ? 'border-amber-500 bg-amber-500/5'
            : images.length >= 2 ? 'border-zinc-700 cursor-default'
            : 'border-zinc-700 hover:border-zinc-600 hover:bg-zinc-900/50'
          }`}
        >
          <input ref={fileInputRef} type="file" accept="image/*" multiple onChange={handleFileInput} className="hidden" />
          <input ref={cameraInputRef} type="file" accept="image/*" capture="environment" onChange={handleFileInput} className="hidden" />
          {images.length === 0 ? (
            <div className="space-y-4">
              <div className="w-14 h-14 mx-auto rounded-2xl flex items-center justify-center text-2xl"
                style={{ background: 'rgba(245,158,11,0.1)', border: '1px solid rgba(245,158,11,0.2)' }}>
                🃏
              </div>
              <div>
                <p className="text-zinc-200 font-semibold text-sm mb-1">
                  Drop card image <span className="text-amber-400">here</span> or click to browse
                </p>
                <p className="text-zinc-500 text-xs mb-4">Up to 2 images (front + back) — JPG, PNG, WebP</p>
                <div className="flex gap-3 justify-center" onClick={(e) => e.stopPropagation()}>
                  <button
                    onClick={() => fileInputRef.current?.click()}
                    className="px-4 py-2 rounded-lg border border-zinc-700 text-zinc-300 text-xs font-semibold hover:border-zinc-500 transition-all"
                  >
                    📁 Browse Files
                  </button>
                  <button
                    onClick={() => {
                      if (/Mobi|Android/i.test(navigator.userAgent)) {
                        cameraInputRef.current?.click()
                      } else {
                        setShowCamera(true)
                      }
                    }}
                    className="px-4 py-2 rounded-lg border border-amber-500/40 text-amber-400 text-xs font-semibold hover:border-amber-500 transition-all"
                  >
                    📷 Take Photo
                  </button>
                </div>
              </div>
            </div>
          ) : (
            <div className="space-y-4">
              <div className="flex gap-3 flex-wrap justify-center">
                {images.map((img, i) => (
                  <div key={i} className="relative group">
                    <img src={URL.createObjectURL(img)} alt={i === 0 ? 'Card front' : 'Card back'}
                      className="w-24 h-32 object-cover rounded-lg border border-zinc-700" />
                    <div className="absolute top-1 left-1 bg-zinc-900/90 text-amber-400 text-xs px-1.5 py-0.5 rounded font-semibold">
                      {i === 0 ? 'FRONT' : 'BACK'}
                    </div>
                    <button onClick={(e) => { e.stopPropagation(); removeImage(i) }}
                      className="absolute top-1 right-1 bg-red-600 text-white rounded-full w-5 h-5 text-xs flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                      ✕
                    </button>
                  </div>
                ))}
              </div>
              {images.length < 2 && <p className="text-zinc-500 text-xs">+ Add back image (optional)</p>}
              {images.length >= 2 && <p className="text-zinc-500 text-xs">Both sides loaded. Ready to grade.</p>}
            </div>
          )}
        </div>

        {/* Error */}
        {error && (
          <div className="bg-red-950/40 border border-red-500/30 rounded-xl px-4 py-3 text-red-400 text-sm">{error}</div>
        )}

        {/* Grade Button */}
        <button
          onClick={gradeCard}
          disabled={images.length === 0 || loading || !apiKey.trim()}
          className="w-full py-4 rounded-xl font-black text-base tracking-wider uppercase transition-all disabled:opacity-40 disabled:cursor-not-allowed"
          style={{
            background: images.length > 0 && !loading && apiKey.trim()
              ? 'linear-gradient(135deg, #f59e0b, #d97706)'
              : 'rgba(245,158,11,0.3)',
            color: '#000',
            boxShadow: images.length > 0 && !loading && apiKey.trim() ? '0 0 24px rgba(245,158,11,0.4)' : 'none',
          }}
        >
          {loading ? (
            <span className="flex items-center justify-center gap-2">
              <span className="animate-spin inline-block w-4 h-4 border-2 border-black/30 border-t-black rounded-full" />
              {loadingStep || 'Grading…'}
            </span>
          ) : '⚡ Grade This Card'}
        </button>

        {/* Report */}
        {report && (
          <div className="space-y-6" style={{ animation: 'fadeIn 0.4s ease-out' }}>

            {/* Annotated Image */}
            <div>
              <div className="flex items-center gap-2 mb-3">
                <div className="h-px flex-1 bg-zinc-800" />
                <span className="text-xs font-semibold text-zinc-500 uppercase tracking-widest">Flaw Map</span>
                <div className="h-px flex-1 bg-zinc-800" />
              </div>
              <AnnotatedImage
                imageFile={images[0]}
                report={report}
                selectedCategory={selectedCategory}
                onSelectCategory={(cat) => setSelectedCategory(cat)}
              />
            </div>

            {/* Overall */}
            <div>
              <div className="flex items-center gap-2 mb-3">
                <div className="h-px flex-1 bg-zinc-800" />
                <span className="text-xs font-semibold text-zinc-500 uppercase tracking-widest">Overall Grade</span>
                <div className="h-px flex-1 bg-zinc-800" />
              </div>
              <OverallGrade overall={report.overall} />
            </div>

            {/* Category Breakdown */}
            <div>
              <div className="flex items-center gap-2 mb-3">
                <div className="h-px flex-1 bg-zinc-800" />
                <span className="text-xs font-semibold text-zinc-500 uppercase tracking-widest">Category Breakdown</span>
                <div className="h-px flex-1 bg-zinc-800" />
              </div>
              {avgScore && (
                <div className="mb-4 p-3 bg-zinc-900 border border-zinc-800 rounded-xl flex items-center gap-4">
                  <div className="text-zinc-500 text-xs uppercase tracking-wider font-semibold">Avg Score</div>
                  <div className="flex-1 bg-zinc-800 rounded-full h-2 overflow-hidden">
                    <div className="h-full rounded-full transition-all duration-700"
                      style={{ width: `${(avgScore / 10) * 100}%`, background: getScoreColor(parseFloat(avgScore)) }} />
                  </div>
                  <span className={`font-black text-sm ${getScoreTextClass(parseFloat(avgScore))}`}>{avgScore}</span>
                </div>
              )}
              <div className="space-y-3">
                {Object.keys(CATEGORY_CONFIG).map((key) =>
                  report[key] ? (
                    <CategoryCard
                      key={key}
                      categoryKey={key}
                      data={report[key]}
                      isHighlighted={selectedCategory === key}
                      onClick={() => handleCategoryClick(key)}
                    />
                  ) : null
                )}
              </div>
            </div>

            {/* Seller Export Tools */}
            <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-4 space-y-3">
              <p className="text-xs font-semibold text-zinc-500 uppercase tracking-widest">Seller Tools</p>
              <p className="text-zinc-400 text-xs">Share this report with buyers — attach the grade card image to your listing or copy the text summary.</p>
              <div className="flex flex-col sm:flex-row gap-2">
                <button
                  onClick={async () => {
                    const dataUrl = await generateGradeCard(report, cardName)
                    const a = document.createElement('a')
                    a.href = dataUrl
                    a.download = `cardscore-${Date.now()}.png`
                    a.click()
                  }}
                  className="flex-1 py-2.5 rounded-lg font-semibold text-sm flex items-center justify-center gap-2 transition-all border border-amber-500/40 text-amber-400 hover:border-amber-500 hover:bg-amber-500/5"
                >
                  ⬇ Download Grade Card
                </button>
                <button
                  onClick={() => {
                    copyListingText(report, cardName)
                    setCopied(true)
                    setTimeout(() => setCopied(false), 2500)
                  }}
                  className="flex-1 py-2.5 rounded-lg font-semibold text-sm flex items-center justify-center gap-2 transition-all border border-zinc-700 text-zinc-300 hover:border-zinc-500"
                >
                  {copied ? '✓ Copied!' : '📋 Copy for Listing'}
                </button>
              </div>
            </div>

            {/* Reset */}
            <button
              onClick={() => { setImages([]); setReport(null); setError(null); setSelectedCategory(null); setCardName('') }}
              className="w-full py-3 rounded-xl border border-zinc-700 text-zinc-400 text-sm font-semibold hover:border-zinc-600 hover:text-zinc-200 transition-all"
            >
              Grade Another Card
            </button>
          </div>
        )}
      </main>

      <footer className="border-t border-zinc-800/60 mt-16 py-6 text-center text-zinc-600 text-xs">
        CardScore · AI-powered card grading · Not affiliated with PSA, BGS, or SGC
      </footer>

      <style>{`
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(8px); }
          to { opacity: 1; transform: translateY(0); }
        }
      `}</style>
    </div>
    </>
  )
}
