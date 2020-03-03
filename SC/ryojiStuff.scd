TempoClock.default.tempo = 1.15

(
~reverb = Bus.alloc(\audio, s, 2);
~reverbUGen.free;
~reverbUGen = {
	|amp=0.5|
	Out.ar([0,1], GVerb.ar(In.ar(~reverb)) * amp)
}.play;
)

// ~reverbUGen.set(\amp, 0.5);

(
x = SynthDef(\resoTick, {
	|freq=1000, ringTime = 1, amp=1|
	var resNoise = Klank.ar(`[[freq], nil, [ringTime]], HPF.ar(PinkNoise.ar([0.5, 0.5]), 10000));
	var env = EnvGen.kr(Env.perc(0.000001, ringTime), doneAction: 2);
	resNoise = resNoise * env * amp;
	Out.ar([~reverb],  resNoise);
	Out.ar([0], resNoise);
}).add;
SynthDef(\oneTick, {
	|dur=0.01, amp=1, hpFreq=1000|
	var env = Line.kr(1.0, 0.1, dur, doneAction: 2);
	var src = Impulse.ar(10);
	src = HPF.ar(src, hpFreq);
	src = src * env * amp;
	Out.ar([0,1], src);
		Out.ar(~reverb, src!2 * 0.1);
}).add;
SynthDef(\sinBlock, {
	|freq=200, amp=1, dur=0.1, gate = 1, curve=0|
	var env = EnvGen.kr(Env.asr(0.000000000001, 1, 0.0000001, curve: curve), gate: gate, doneAction: 2);
	var src = SinOsc.ar(freq, LFDNoise0.kr(1/10)) * env * amp;
	src = src + BPF.ar(PinkNoise.ar(0.005), freq);
	Out.ar([0,1], src);
}).add;
)
(
p.stop;
p = Pbind(\instrument, \resoTick,
	\delta, TempoClock.default.tempo * 8,
	\freq, Pseq(((14000!7)++2800).rotate(0), inf),
	\ringTime, Pseq(((4!7)++6).rotate(0), inf),
	\amp, Pseq([1, 0.6], inf) * 0.15
).play(TempoClock.default, quant: Quant.new(1, 2));
~p2.stop;
~p2 = Pbind(\instrument, \resoTick,
	\delta, TempoClock.default.tempo * (2/3),
	\freq, 14000,
	\ringTime, Pseq([0.1,0.05], inf),
	\amp, Pseq([0.5, 1, 0.5], inf)
).play(TempoClock.default, quant: Quant.new(1));
~p3.stop;
~p3 = Pbind(\instrument, \oneTick,
 	\delta, TempoClock.default.tempo * Pseq([1,0.5], inf),
	\dur, Pseq(((0.05!35)++0.5), inf),
 	\amp, Pseq([0.7, 0.5], inf) * Pseq(((0.4)!12) ++ ((0.6)!12), inf),
).play(TempoClock.default, quant: Quant.new(1));
~p4.stop;
~p4 = Pbind(\instrument, \oneTick,
	\delta, TempoClock.default.tempo * (1/3),
	\dur, 0.05,
	\hpFreq, 10000,
	\amp, Pseq([0.7, 0.5], inf),
).play(TempoClock.default, quant: Quant.new(1));
~p5.stop;
~p5 = Pbind(\instrument, \sinBlock,
	\delta, TempoClock.default.tempo * Pseq([1, 2], inf) * Pseq((1!11) ++ 4, inf),
	\dur, TempoClock.default.tempo * Pseq(((1/2)!3) ++ (2/3), inf) * Pseq((0.75!8) ++ (1!4), inf),
	\freq, Pseq(Scale.chromatic.ratios.at([0, 0, 1, 0, 0, 0, 0, 0]), inf) * 32.midicps,
	\amp, 0.07
).play(TempoClock.default, quant: Quant.new(1));
~p6.stop;
~p6 = Pbind(
	\amp, 0,
	\delta, TempoClock.default.tempo * Pseq([16, 4], inf),
	\index, Pseq([0, 1], inf),
	\func, Pfunc({|i| i.index.postln; if(i.index==0, {~reverbUGen.set(\amp, 0.2);}, {~reverbUGen.set(\amp, 0);})});
).play(TempoClock.default, quant: Quant.new(1));
)

/*
Visuals: per sound get a group
Bass: 4, display horizontal bar					5
Tick: small rect											5
High res noise: All white, decay				5
High-hat noise: Two L & R vert beams?		5
*/