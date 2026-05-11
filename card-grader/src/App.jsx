import { useState, useCallback, useRef } from 'react'

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

Return ONLY a valid JSON object with no markdown, no explanation, no extra text:
{
  "centering": {
    "score": <number 1-10>,
    "label": "<e.g. 'Excellent' | 'Near Mint' | 'Gem Mint'>",
    "explanation": "<1-2 sentence expert analysis>",
    "issues": ["<specific issue>", ...]
  },
  "corners": {
    "score": <number 1-10>,
    "label": "<label>",
    "explanation": "<analysis>",
    "issues": ["<issue>", ...]
  },
  "edges": {
    "score": <number 1-10>,
    "label": "<label>",
    "explanation": "<analysis>",
    "issues": ["<issue>", ...]
  },
  "surface": {
    "score": <number 1-10>,
    "label": "<label>",
    "explanation": "<analysis>",
    "issues": ["<issue>", ...]
  },
  "printQuality": {
    "score": <number 1-10>,
    "label": "<label>",
    "explanation": "<analysis>",
    "issues": ["<issue>", ...]
  },
  "overall": {
    "numericGrade": <number>,
    "psaLabel": "<e.g. 'GEM MINT 10' | 'NM-MT 8'>",
    "summary": "<2-3 sentence overall assessment>",
    "gradeHurting": ["<factor hurting the grade>", ...],
    "submissionTips": ["<actionable tip>", ...]
  }
}`

const CATEGORY_CONFIG = {
  centering: { label: 'Centering', description: 'Border ratios & alignment', icon: '⊞' },
  corners: { label: 'Corners', description: 'Sharpness of all 4 corners', icon: '◇' },
  edges: { label: 'Edges', description: 'Condition of all 4 edges', icon: '▭' },
  surface: { label: 'Surface', description: 'Card face & back condition', icon: '◈' },
  printQuality: { label: 'Print Quality', description: 'Color, focus & registration', icon: '◉' },
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

function CategoryCard({ categoryKey, data }) {
  const [expanded, setExpanded] = useState(false)
  const cfg = CATEGORY_CONFIG[categoryKey]

  return (
    <div
      className="bg-zinc-900 border border-zinc-800 rounded-xl overflow-hidden cursor-pointer hover:border-zinc-700 transition-colors"
      onClick={() => setExpanded((e) => !e)}
    >
      <div className="p-4 flex items-center gap-4">
        <ScoreRing score={data.score} size={72} />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-0.5">
            <span className="text-zinc-400 text-xs">{cfg.icon}</span>
            <span className="font-bold text-zinc-100 text-sm uppercase tracking-wider">{cfg.label}</span>
          </div>
          <p className="text-zinc-500 text-xs mb-1">{cfg.description}</p>
          <span
            className="inline-block px-2 py-0.5 rounded-full text-xs font-semibold"
            style={{
              backgroundColor: `${getScoreColor(data.score)}20`,
              color: getScoreColor(data.score),
            }}
          >
            {data.label}
          </span>
        </div>
        <div className="text-zinc-600 text-xs select-none">{expanded ? '▲' : '▼'}</div>
      </div>

      {expanded && (
        <div className="border-t border-zinc-800 px-4 pb-4 pt-3 space-y-3">
          <p className="text-zinc-300 text-sm leading-relaxed">{data.explanation}</p>
          {data.issues && data.issues.length > 0 && (
            <div>
              <p className="text-zinc-500 text-xs uppercase tracking-wider mb-2 font-semibold">Issues Detected</p>
              <ul className="space-y-1">
                {data.issues.map((issue, i) => (
                  <li key={i} className="flex items-start gap-2 text-sm text-zinc-400">
                    <span className="text-red-400 mt-0.5 flex-shrink-0">✕</span>
                    {issue}
                  </li>
                ))}
              </ul>
            </div>
          )}
          {(!data.issues || data.issues.length === 0) && (
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
        <div className="flex-1 space-y-3">
          <p className="text-zinc-200 text-sm leading-relaxed">{overall.summary}</p>
        </div>
      </div>

      {overall.gradeHurting && overall.gradeHurting.length > 0 && (
        <div className="mt-5 pt-5 border-t border-zinc-800">
          <p className="text-xs uppercase tracking-wider font-semibold text-zinc-500 mb-3">
            What's Hurting Your Grade
          </p>
          <div className="flex flex-wrap gap-2">
            {overall.gradeHurting.map((factor, i) => (
              <span
                key={i}
                className="px-3 py-1 rounded-full text-xs font-medium bg-red-500/10 text-red-400 border border-red-500/20"
              >
                {factor}
              </span>
            ))}
          </div>
        </div>
      )}

      {overall.submissionTips && overall.submissionTips.length > 0 && (
        <div className="mt-5 pt-5 border-t border-zinc-800">
          <p className="text-xs uppercase tracking-wider font-semibold text-zinc-500 mb-3">
            Submission Tips
          </p>
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

function ImagePreview({ images, onRemove }) {
  return (
    <div className="flex gap-3 flex-wrap">
      {images.map((img, i) => (
        <div key={i} className="relative group">
          <img
            src={URL.createObjectURL(img)}
            alt={i === 0 ? 'Card front' : 'Card back'}
            className="w-24 h-32 object-cover rounded-lg border border-zinc-700"
          />
          <div className="absolute top-1 left-1 bg-zinc-900/90 text-amber-400 text-xs px-1.5 py-0.5 rounded font-semibold">
            {i === 0 ? 'FRONT' : 'BACK'}
          </div>
          <button
            onClick={() => onRemove(i)}
            className="absolute top-1 right-1 bg-red-600 text-white rounded-full w-5 h-5 text-xs flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
          >
            ✕
          </button>
        </div>
      ))}
    </div>
  )
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
  const fileInputRef = useRef(null)

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

  const handleDragOver = (e) => {
    e.preventDefault()
    setIsDragging(true)
  }

  const handleDragLeave = () => setIsDragging(false)

  const handleFileInput = (e) => {
    addImages(e.target.files)
    e.target.value = ''
  }

  const gradeCard = async () => {
    if (images.length === 0) return
    if (!apiKey.trim()) {
      setError('Please enter your Anthropic API key.')
      return
    }

    setLoading(true)
    setError(null)
    setReport(null)

    try {
      setLoadingStep('Encoding images…')
      const imageBlocks = await Promise.all(
        images.map(async (file, i) => {
          const b64 = await fileToBase64(file)
          const mediaType = file.type || 'image/jpeg'
          return [
            {
              type: 'text',
              text: i === 0 ? 'Card front image:' : 'Card back image:',
            },
            {
              type: 'image',
              source: { type: 'base64', media_type: mediaType, data: b64 },
            },
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
          messages: [
            {
              role: 'user',
              content: [
                ...imageBlocks.flat(),
                { type: 'text', text: 'Please grade this trading card and return the JSON analysis.' },
              ],
            },
          ],
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
        [
          report.centering?.score,
          report.corners?.score,
          report.edges?.score,
          report.surface?.score,
          report.printQuality?.score,
        ]
          .filter(Boolean)
          .reduce((a, b) => a + b, 0) /
        [
          report.centering?.score,
          report.corners?.score,
          report.edges?.score,
          report.surface?.score,
          report.printQuality?.score,
        ].filter(Boolean).length
      ).toFixed(1)
    : null

  return (
    <div className="min-h-screen bg-zinc-950" style={{ fontFamily: 'Inter, system-ui, sans-serif' }}>
      {/* Header */}
      <header className="border-b border-zinc-800/60 bg-zinc-950/80 backdrop-blur sticky top-0 z-10">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div
              className="w-8 h-8 rounded-lg flex items-center justify-center text-sm font-black"
              style={{ background: 'linear-gradient(135deg, #f59e0b, #d97706)' }}
            >
              V
            </div>
            <div>
              <span className="font-black text-zinc-100 tracking-tight">VaultGrade</span>
              <span className="text-amber-500 text-xs ml-1.5 font-semibold uppercase tracking-widest">AI</span>
            </div>
          </div>
          <div className="flex items-center gap-2 text-xs text-zinc-500">
            <span
              className="w-1.5 h-1.5 rounded-full"
              style={{ background: '#f59e0b', boxShadow: '0 0 4px #f59e0b' }}
            />
            Powered by Claude Vision
          </div>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-4 py-8 space-y-6">
        {/* Hero */}
        <div className="text-center pt-4 pb-2">
          <h1 className="text-3xl sm:text-4xl font-black text-zinc-100 leading-tight mb-2">
            Professional Card{' '}
            <span
              style={{
                background: 'linear-gradient(135deg, #f59e0b, #d97706, #fbbf24)',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
              }}
            >
              Grading
            </span>
          </h1>
          <p className="text-zinc-400 text-sm max-w-md mx-auto">
            Upload 1–2 card images. Claude Vision analyzes centering, corners, edges, surface, and print quality to
            deliver a PSA-style grade report.
          </p>
        </div>

        {/* API Key Input */}
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
          <button
            onClick={() => setShowKeyInput(true)}
            className="text-xs text-zinc-600 hover:text-zinc-400 transition-colors"
          >
            Change API key
          </button>
        )}

        {/* Upload Zone */}
        <div
          onDrop={handleDrop}
          onDragOver={handleDragOver}
          onDragLeave={handleDragLeave}
          onClick={() => images.length < 2 && fileInputRef.current?.click()}
          className={`rounded-2xl border-2 border-dashed p-8 text-center transition-all cursor-pointer ${
            isDragging
              ? 'border-amber-500 bg-amber-500/5'
              : images.length >= 2
              ? 'border-zinc-700 cursor-default'
              : 'border-zinc-700 hover:border-zinc-600 hover:bg-zinc-900/50'
          }`}
        >
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            multiple
            onChange={handleFileInput}
            className="hidden"
          />

          {images.length === 0 ? (
            <div className="space-y-3">
              <div
                className="w-14 h-14 mx-auto rounded-2xl flex items-center justify-center text-2xl"
                style={{ background: 'rgba(245,158,11,0.1)', border: '1px solid rgba(245,158,11,0.2)' }}
              >
                🃏
              </div>
              <div>
                <p className="text-zinc-200 font-semibold text-sm mb-1">
                  Drop card image{' '}
                  <span className="text-amber-400">here</span> or click to browse
                </p>
                <p className="text-zinc-500 text-xs">Up to 2 images (front + back) — JPG, PNG, WebP</p>
              </div>
            </div>
          ) : (
            <div className="space-y-4">
              <ImagePreview images={images} onRemove={removeImage} />
              {images.length < 2 && (
                <p className="text-zinc-500 text-xs">
                  + Add back image (optional)
                </p>
              )}
              {images.length >= 2 && (
                <p className="text-zinc-500 text-xs">Both sides loaded. Ready to grade.</p>
              )}
            </div>
          )}
        </div>

        {/* Error */}
        {error && (
          <div className="bg-red-950/40 border border-red-500/30 rounded-xl px-4 py-3 text-red-400 text-sm">
            {error}
          </div>
        )}

        {/* Grade Button */}
        <button
          onClick={gradeCard}
          disabled={images.length === 0 || loading || !apiKey.trim()}
          className="w-full py-4 rounded-xl font-black text-base tracking-wider uppercase transition-all disabled:opacity-40 disabled:cursor-not-allowed relative overflow-hidden"
          style={{
            background:
              images.length > 0 && !loading && apiKey.trim()
                ? 'linear-gradient(135deg, #f59e0b, #d97706)'
                : 'rgba(245,158,11,0.3)',
            color: '#000',
            boxShadow:
              images.length > 0 && !loading && apiKey.trim()
                ? '0 0 24px rgba(245,158,11,0.4)'
                : 'none',
          }}
        >
          {loading ? (
            <span className="flex items-center justify-center gap-2">
              <span className="animate-spin inline-block w-4 h-4 border-2 border-black/30 border-t-black rounded-full" />
              {loadingStep || 'Grading…'}
            </span>
          ) : (
            '⚡ Grade This Card'
          )}
        </button>

        {/* Report */}
        {report && (
          <div className="space-y-6 animate-in" style={{ animation: 'fadeIn 0.4s ease-out' }}>
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

              {/* Average bar */}
              {avgScore && (
                <div className="mb-4 p-3 bg-zinc-900 border border-zinc-800 rounded-xl flex items-center gap-4">
                  <div className="text-zinc-500 text-xs uppercase tracking-wider font-semibold">Avg Score</div>
                  <div className="flex-1 bg-zinc-800 rounded-full h-2 overflow-hidden">
                    <div
                      className="h-full rounded-full transition-all duration-700"
                      style={{
                        width: `${(avgScore / 10) * 100}%`,
                        background: getScoreColor(parseFloat(avgScore)),
                      }}
                    />
                  </div>
                  <span className={`font-black text-sm ${getScoreTextClass(parseFloat(avgScore))}`}>{avgScore}</span>
                </div>
              )}

              <div className="space-y-3">
                {Object.keys(CATEGORY_CONFIG).map((key) =>
                  report[key] ? (
                    <CategoryCard key={key} categoryKey={key} data={report[key]} />
                  ) : null
                )}
              </div>
            </div>

            {/* Reset */}
            <button
              onClick={() => {
                setImages([])
                setReport(null)
                setError(null)
              }}
              className="w-full py-3 rounded-xl border border-zinc-700 text-zinc-400 text-sm font-semibold hover:border-zinc-600 hover:text-zinc-200 transition-all"
            >
              Grade Another Card
            </button>
          </div>
        )}
      </main>

      <footer className="border-t border-zinc-800/60 mt-16 py-6 text-center text-zinc-600 text-xs">
        VaultGrade · AI-powered card grading · Not affiliated with PSA, BGS, or SGC
      </footer>

      <style>{`
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(8px); }
          to { opacity: 1; transform: translateY(0); }
        }
      `}</style>
    </div>
  )
}
