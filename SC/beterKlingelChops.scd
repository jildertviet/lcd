(
f = Buffer.read(s, "/Users/jildertviet/Music/JildertMusic/Samples/Regular/Self Made/Belletjes.wav");
g = Buffer.read(s, "/Users/jildertviet/Music/JildertMusic/Samples/Regular/Self Made/Gong (Lampenkap).wav");
h = Buffer.read(s, "/Users/jildertviet/Music/JildertMusic/Samples/Regular/Self Made/Mes Slijpen.wav");
)
(
x = SynthDef(\sample, {
	|amp=1, buf, startPos=0, trig=0, rate=1, hpf=1000|
	var sample;
	sample = PlayBuf.ar(2, buf, rate, trig, startPos, 1);
	sample = HPF.ar(sample, hpf);
	Out.ar(0, sample * amp);
}).add;
)

(
x.free; x = Synth(\sample, [buf: f, startPos: f.numFrames * 0.5]);
y.free; y = Synth(\sample, [buf: g, startPos: g.numFrames * 0.5, rate: 1.016]);

p.stop;
p = Pbind(*[
	type: \set,
	id: x.nodeID,
	args: #[\startPos, \trig, \rate, \amp, \hpf],
	startPos: f.numFrames * Pseq((((1..5)*0.01)+0.6).stutter, inf),
	rate: Pseq(1!4 ++ 1, inf) * Pseq(1!4 ++ (-1), inf) * 0.75,
	trig: Pseq([-1, 1], inf),
	amp: Pseq([1, 0.5, 0.25, 0.5], inf) * Pseq(0.25!16 ++ (0.5!16), inf) * 0.5,
	hpf: Pseq(3!3 ++ 4 * 1000, inf),
	delta: Pseq([1, 0.5, 2, 0.25, 1], inf) * 0.125 * 1
]).play;
q.stop;
q = Pbind(*[
	type: \set,
	id: y.nodeID,
	args: #[\startPos, \trig, \rate, \amp, \hpf],
	startPos: g.numFrames * (Pseq((((1..5)*0.01)).stutter, inf) + Pseq((0.1!4 ++ (0.2!3)).foldExtend(32*4) ++ (0.5+(((1..4)/4)*0.02)), inf)),
	rate: Pseq(1!4 ++ 1, inf) * Pseq(1!4 ++ (-1), inf) * 1.016,
	trig: Pseq([-1, 1], inf),
	amp: Pseq([1, 0.5, 0.25, 0.5], inf),
	hpf: Pseq(1!3 ++ 2, inf) * Pseq(200!16 ++ (30!8), inf),
	delta: Pseq([1, 0.5, 2, 0.25, 1].rotate(3), inf) * 0.125
]).play;
z.free; z = Synth(\sample, [buf: h, startPos: h.numFrames * 0.01, amp: 0]);
u.stop;
u = Pbind(*[
	type: \set,
	id: z.nodeID,
	args: #[\startPos, \trig, \rate, \amp, \hpf],
	startPos: h.numFrames * (Pseq((((1..5)*0.01)).stutter, inf) + Pseq([0.7], inf)),
	rate: Pseq(1!4 ++ 1, inf) * Pseq(1!4 ++ (-1), inf),
	trig: Pseq([-1, 1], inf),
	amp: Pseq([1, 0.25, 0.25, 0.5], inf) * Pseq((0.5!16) ++ (1!16), inf) * 0.5,
	hpf: Pseq([5000], inf),
	delta: Pseq([1, 0.5, 2, 0.25, 1].rotate(6), inf) * 0.125
]).play;
r.free; r = {LFPulse.kr(0.25, width: 1/8) * (HPF.ar(GrayNoise.ar(0.01), 10000)+SinOsc.ar(51.913087197493, mul:  0.025))!2}.play;
)

// v.free; v = {Lag.ar(LFPulse.ar(0.5, width: 0.1, mul: 0.1)!2, 0.0000001)}.play;