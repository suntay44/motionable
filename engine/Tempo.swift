// motionable engine: tempo phases. Most films keep one tempo. A film whose story wants it (plan mode decides, from the
// product and what the user wants) can change tempo on purpose, the way a producer would:
//   · from a beat on, with a musical way in: a tape stop, a hit and a beat of silence, a riser, or a plain cut;
//   · a ramp: speeding up into a drop, or slowing into the end.
// Half-time and double-time grooves keep the tempo and change the feel instead (a Section's `feel`): the easiest way to
// make a stretch feel slower or faster while every cut stays on the grid. Picture and music read the same map, so a
// film's `T.b(n)` should be `phases.time(ofBeat: n)` when it has one.
import Foundation

enum TempoChange {
    /// From `beat` on, play at `bpm`; `via` is how the music gets there.
    case at(beat: Double, bpm: Double, via: TempoMap.Way = .cut)
    /// Between `from` and `to` (beats), glide from the tempo at `from` to `bpm`, then stay there.
    case ramp(from: Double, to: Double, bpm: Double)
}

struct TempoMap {
    /// How the music moves into a new tempo.
    enum Way { case cut, tapeStop, hitStop, riser }
    private struct Segment { let b0: Double, b1: Double, bpm0: Double, bpm1: Double, t0: Double }
    private let segments: [Segment]
    let base: Double
    /// Tempo changes that the music marks (film time, and how), for the composer.
    let marks: [(t: Double, way: Way)]

    init(_ bpm: Double, _ changes: [TempoChange] = []) {
        base = bpm
        // Breakpoints in beats: each with the tempo arriving there, and whether the stretch before it glides.
        var points: [(b: Double, bpm: Double, glide: Bool, way: Way?)] = [(0, bpm, false, nil)]
        for c in changes {
            switch c {
            case .at(let b, let v, let way): points.append((b, v, false, way))
            case .ramp(let a, let z, let v): points.append((a, -1, false, nil)); points.append((z, v, true, nil))
            }
        }
        points.sort { $0.b < $1.b }
        var segs: [Segment] = [], marks: [(Double, Way)] = []
        var b = 0.0, v = bpm, t = 0.0
        for p in points.dropFirst() where p.b > b || p.bpm >= 0 {
            let end = p.bpm < 0 ? v : (p.glide ? p.bpm : v)                 // a ramp's start keeps the tempo so far
            if p.b > b {
                segs.append(Segment(b0: b, b1: p.b, bpm0: v, bpm1: end, t0: t))
                t += TempoMap.seconds(from: b, to: p.b, v, end, over: p.b - b)
                b = p.b; v = end
            }
            if p.bpm >= 0 && !p.glide { if let w = p.way { marks.append((t, w)) }; v = p.bpm }
        }
        segs.append(Segment(b0: b, b1: .infinity, bpm0: v, bpm1: v, t0: t))
        segments = segs
        self.marks = marks
    }

    /// Seconds for `beats` beats whose tempo moves linearly (in beats) from `v0` to `v1` over a span of `span` beats.
    private static func seconds(from b0: Double, to b1: Double, _ v0: Double, _ v1: Double, over span: Double) -> Double {
        let k = (v1 - v0) / max(1e-9, span)
        let db = b1 - b0
        if abs(k) < 1e-9 { return db * 60 / v0 }
        return 60 / k * log((v0 + k * db) / v0)
    }

    /// The film time of beat `b` (beat 0 is the start of the film).
    func time(ofBeat b: Double) -> Double {
        guard b > 0 else { return b * 60 / base }
        let s = segments.last { b >= $0.b0 } ?? segments[0]
        let span = s.b1.isFinite ? s.b1 - s.b0 : 1
        return s.t0 + TempoMap.seconds(from: s.b0, to: b, s.bpm0, s.b1.isFinite ? s.bpm1 : s.bpm0, over: s.b1.isFinite ? span : 1)
    }

    /// The beat at film time `t` (fractional).
    func beat(at t: Double) -> Double {
        guard t > 0 else { return t * base / 60 }
        let s = segments.last { t >= $0.t0 } ?? segments[0]
        let dt = t - s.t0
        let k = s.b1.isFinite ? (s.bpm1 - s.bpm0) / (s.b1 - s.b0) : 0
        if abs(k) < 1e-9 { return s.b0 + dt * s.bpm0 / 60 }
        return s.b0 + (s.bpm0 * exp(k * dt / 60) - s.bpm0) / k
    }

    /// The tempo at film time `t`, and the length of one beat there.
    func bpm(at t: Double) -> Double {
        let b = beat(at: t)
        let s = segments.last { b >= $0.b0 } ?? segments[0]
        guard s.b1.isFinite, s.b1 > s.b0 else { return s.bpm0 }
        return s.bpm0 + (s.bpm1 - s.bpm0) * (b - s.b0) / (s.b1 - s.b0)
    }
    func secondsPerBeat(at t: Double) -> Double { 60 / bpm(at: t) }

    /// How far into the current beat `t` is (0…1): for pulses and pumps that follow the tempo.
    func phase(at t: Double) -> Double { let b = beat(at: t); return b - floor(b) }
}

/// The film's tempo map (set from `Film.tempo`, or one tempo at `Film.bpm`).
var tempoMap = TempoMap(120)

/// A small zoom that breathes on every beat of the tempo map (add to the camera scale).
func beatPulse(_ t: Double, amount: Double = 0.006) -> Double {
    amount * exp(-tempoMap.phase(at: t) * tempoMap.secondsPerBeat(at: t) * 14)
}
