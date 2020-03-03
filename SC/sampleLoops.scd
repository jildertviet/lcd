(
~tape = Buffer.read(s, "/Users/jildertviet/Music/Tape-Ball_1.aif");
c = Buffer.read(s, "/Users/jildertviet/Music/Broken-Glass_1.aif");
d = Buffer.read(s, "/Users/jildertviet/Music/JildertMusic/synth.wav");
e = Buffer.read(s, "/Users/jildertviet/Music/JildertMusic/Samples/Regular/Undefined/Elevator.wav");
)
(
x.free; x = {
	var buf = ~tape;
	var out = PlayBuf.ar(buf.numChannels, buf.bufnum, 1, LFPulse.kr(1, (1..4)/4), Array.fill(4, {buf.numFrames.rand.postln}));
	Out.ar(0, out * 10);
}.play;
)
(
y.free; y = {
	var trig;
	var bufPlay = PlayBuf.ar(c.numChannels, c.bufnum, 1 * 1, LFPulse.kr(1, (1..4)/4), Array.fill(4, {c.numFrames.rand.postln;}));
	trig = Trig.ar((bufPlay*4).round(0.1), 0.1);
	trig = Trig.ar(trig, 0.00001) * 20;
	trig = trig.min(1);
	bufPlay = BPF.ar(bufPlay, 5000, 0.2, 10) * 1;
	trig = HPF.ar(trig, 1000);
	bufPlay = bufPlay + trig;
	Out.ar(0, bufPlay * 4);
}.play;
)
// 2671781,9901105,12962782,14779294 rate:-1
// 8144106,9981640,8528267,2708655 rate:-1
// 5550064,11785578,11443089,16716753 rate:1

(
z.free; z = {
	var trig;
	var widths = (1..4)/5;
	var lfPulseFreq = 1;
	var phases = (1..4)/6;
	// var widths = 0.5;
	var bufPlay = PlayBuf.ar(d.numChannels, d.bufnum, 1 * 1, LFPulse.kr(lfPulseFreq, phases, widths), Array.fill(4, {(d.numFrames*0.75).rand.postln;}));
	trig = Trig.ar((bufPlay*4).round(0.1), 0.1);
	trig = Trig.ar(trig, 0.00001) * 20;
	trig = trig.min(1);
	bufPlay = BPF.ar(bufPlay, 5000, 0.2, 10) * 1;
	trig = HPF.ar(trig, 1000);
	// bufPlay = Mix.ar(bufPlay)!2;
	// bufPlay = Mix.ar([bufPlay[0], bufPlay[1]], bufPlay[2], bufPlay[3]);
	Out.ar(0, bufPlay * 10);
}.play;
)
// Widths: 0.5, lfPulseFreq: 1, phases: (1..4)/4
54601,61699,49933,43727
45744,36389,43327,42970
22915,15044,24998,17481
// Width:  (1..4)/5;, 1, (1..4)/6;
2021, 32520, 14964, 63345

(
r.free; r = {
	var trig;
	var widths = (1..4)/5;
	var lfPulseFreq = 1;
	var phases = (1..4)/6;
	// var widths = 0.5;
	var bufPlay = PlayBuf.ar(e.numChannels, e.bufnum, 1 * 1, LFPulse.kr(lfPulseFreq, phases, widths), Array.fill(4, {e.numFrames.rand.postln;}));
	trig = Trig.ar((bufPlay*4).round(0.1), 0.1);
	trig = Trig.ar(trig, 0.00001) * 20;
	trig = trig.min(1);
	bufPlay = BPF.ar(bufPlay, 5000, 0.2, 10) * 1;
	trig = HPF.ar(trig, 1000);
	bufPlay = bufPlay;
	Out.ar(0, bufPlay * 4);
}.play;
)

25926,179711,722066,316136

62131,299912,729328,727553