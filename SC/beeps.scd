(
~brokenGlass = Buffer.readChannel(s, "/Users/jildertviet/Music/Broken-Glass_1.aif", channels: 1);
~levelsBeeps = Bus.alloc(\control, s, 6).setn(1!6);

SynthDef(\sample,{
	|r=0, gate=1, gain=1, c=0, startRatio=0, lpf=1000, rate=1, buf=0, ampBus=1|
	var env = EnvGen.kr(Env.adsr(releaseTime: r, curve: c),gate, doneAction: 2);
	var play = PlayBuf.ar(1, buf, rate, startPos: BufDur.ir(buf) * startRatio);
	play = LPF.ar(play, lpf);
	Out.ar([0,1], play * gain * env * ampBus);
}).add;

SynthDef(\sin, {
	|freq=100, amp=1, gate=1, pan=0, ampBus=1|
	var sin = 	SinOsc.ar(freq) * amp;
	var env = EnvGen.kr(Env.adsr(releaseTime: 0), gate, doneAction: 2);
	var p = Pan2.ar(sin, pan);
	Out.ar(0, p * ampBus);
}).add;

SynthDef(\noisePulses, {
	|ampBus =1, gate=1, release=8|
	var env = EnvGate(1, gate, release);
	var numNoises = 4;
	var amp = Array.fill(numNoises, {|i|
		pow(LFTri.kr(LFPulse.kr(1/12, width: 3/4).range(0.5, 1), (i/numNoises)*4, mul: 0.5, add: 0.5), LFPulse.kr(1.5, width: 3/4,  mul: LFPulse.kr(1, width: 1/4) + 1) + 1);
	});
	var out =	PinkNoise.ar(0.1) * amp[0];
	var base;
	var signal;
	signal = Trig.kr(amp[1].round(1.0), 0.4);
	signal = SendTrig.kr(signal, 0, signal);
	out = out + (WhiteNoise.ar(0.1) * amp[1]);
	out = out + (BrownNoise .ar(0.1) * amp[2]);
	out = out + (GrayNoise.ar(0.1) * amp[3]);
	base = SinOsc.ar((1..2)*2000 + 5000);
	out = base * out;
	out = HPF.ar(out,  13000)!2;
	Out.ar(0, out * ampBus * env);
}).add;

SynthDef(\cracklingNoise, {
	|ampBus=1, release=2, gate=1|
	var env = EnvGate(1, gate, release);
	var sin = SinOsc.ar(LFPulse.kr(0.5, width: 1/4, mul: 10, add: 1) + [30,60], mul: [0.3,0.1]);
	// var sin = SinOsc.ar(LFPulse.kr(0.5, width: 1/4, mul: 10, add: 1) + 30, mul: 0.3);
	var pulse = HPF.ar(LFPulse.ar([30,15], width: LFPulse.kr(0.25, add: 1)/4), 15000) * 0.35;
	var out;
	sin = (sin * 0.5) + (sin * Lag.kr(pow(1-LFSaw.kr(0.125, 1, mul: 0.5, add: 0.5), 4)));
	out = pulse + sin;
	Out.ar(0, out * ampBus * env);
}).add;

~initLCDsBeeps = {
	~lcd.setVisualizerMode(0);
	// Set groups per voice
	~nodes = (0..24).scramble;
	~sin0Group = ~nodes.at((0..6));
	~sin1Group = ~nodes.at((7..11));
	~sampleClickers = ~nodes.at((12..17));
	~sampleClickersCouple = ~sampleClickers.at([0, 1]);
	~noiseGroup = ~nodes.at((18..24));
	{
		2.do{
		var waitTime = 0.01;
		~sin0Group.do{
			|i|
			~lcd.fillRectClear(i, 0.25 * 255, 0.25 * 255, 0.5 * 255, 0.5 * 255, 255, 255, 255);
			waitTime.wait;
		};
		~sin1Group.do{
			|i|
			var color = [255, 255, 255];
			~lcd.fillRectClear(i, [0, 0.5].choose * 255, [0, 0.5].choose * 255, 0.5 * 255, 0.5 * 255, color[0], color[1], color[2]);
			waitTime.wait;
		};
		~sampleClickers.do{
			|i|
			~lcd.fillRectClear(i, [0,0.5].choose * 255, 0, 0.5 * 255, 1 * 255, 255, 255, 255);
			waitTime.wait;
		};
		~hTemp = [0.15, 0.1, 0.05].choose;
		~noiseGroup.do{
			|i|
			var h = ~hTemp;
			~lcd.fillRectClear(i, 0, ((1-h)*0.5)*255, 1*255, h*255, 255, 255, 255); // Rect
		};
			0.01.wait;
		}
	}.fork;
};

~startBeepsRoutine = Routine({
	~lcd.setVal(-1, 0); // All off
	~initLCDsBeeps.value();
	0.5.wait;
	~noisePulseReceiver.free;
	~noisePulseReceiver = OSCFunc({ arg msg, time;
		[time, msg].postln;
		~noiseGroup.do{
			|i|
			if(msg[3] == 1.0, {
				// n.sendMsg("/", i, 2, 0, 200, 100, 0, 40, 300, 1000); // Env?
				~lcd.doEnv(i, 200, [40, 300, 1000]);
			});
		}
	},'/tr', s.addr);

	{
		~cracklingNoise = Synth(\cracklingNoise, [ampBus: ~levelsBeeps.subBus(1).asMap]);
		~noisePulsesSynth = Synth(\noisePulses, [ampBus: ~levelsBeeps.subBus(0).asMap]);
	}.fork(TempoClock.default, 1);

~beepOne = Pbind(
	\instrument, \sin,
	\delta, 1,
	\dur, Pseq((0.07!31)++ [1], inf),
	\amp, Pseq([0.03, 0.05, 0.04], inf) * 0.7,
	\freq, Pseq([300, 301], inf),
	\ampBus, ~levelsBeeps.subBus(2).asMap,
	\fun, Pfunc({
		|values|
		var dur = values.asArray[1].asFloat;
		var asr = [20, dur*1000-300-20, 300];
		var envVal = 255;
		~sin0Group = ~sin0Group.rotate(1);
		if(values.asArray[1].asFloat == 1, {
			var i = ~sin0Group[0];
			~sin0Group = ~sin0Group.rotate(1);
			~lcd.fillRectClear(i, 0, 0.25 * 255, 1 * 255, 0.5 * 255); // Wide
			~lcd.doEnv(i, envVal, asr);
			{
				((asr.sum)/1000).wait;
				~lcd.fillRectClear(i, 0.25 * 255, 0.25 * 255, 0.5 * 255, 0.5 * 255);
			}.fork;
		}, {
			3.do{
				|j|
				~lcd.doEnv(~sin0Group[j], envVal,  [asr[0], asr[1]+300, asr[2]]);
			}
		});
	});
).play(TempoClock.default, quant: Quant.new(1));

~highBeep = Pbind(
	\instrument, \sin,
	\delta, Pseq([2, 2, 2, 1/8], inf),
	\dur, Pseq((0.3!8) ++ (0.03!31), inf),
	\amp, 0.01,
	\pan, Prand([-1, 0, 1], inf),
	\freq, Pseq([3000], inf),
	\ampBus, ~levelsBeeps.subBus(3).asMap,
	\func, Pfunc({
		|values|
		var pan = values.asArray[3];
		var asr = [20, 200, 100];
		var envVal = 255;
		pan.postln;
		2.do{
			~lcd.doEnv(~sin1Group.choose, envVal, asr);
		}
	});
).play(TempoClock.default, quant: Quant.new(1, 1));

~sampleClickersPattern = Pbind(
\instrument, \sample,
\delta, Pseq(((1/3!4)++(0.25!2)).lace(64*6) ++ (32*4), inf) * 1/8,
\lpf, Pseq([1000, 10000, 20000, 5000], inf),
\gain, 1.5,
\dur, 1/32,
\r, Pseq(1/[16, 8, 2], inf),
\c, 4,
		\buf, ~brokenGlass.bufnum,
\rate, Pseq((2!(32*12))++(1!(32*6)), inf),
\startRatio, Pseq(Array.fill(12, {|i| ((i * pi).asInt % 100) / 100}), inf),
	\ampBus, ~levelsBeeps.subBus(4).asMap,
	\func, Pfunc({
		|values|
		var asr = [10, 100, 10];
		var envVal = 255;
		if(values.asArray[2].asFloat == (1/16), {
			~lcd.doEnv(~sampleClickersCouple[0], envVal, asr);
			~sampleClickersCouple = ~sampleClickersCouple.rotate(1);
			if(values.asArray[7].asFloat == 16.0, {
				"Make new couple".postln;
				~sampleClickers = ~sampleClickers.scramble;
				~sampleClickersCouple = ~sampleClickers.at([0,1]);
				~sampleClickersCouple.postln;
			});
		});
		1;
});
).play(TempoClock.default, quant: Quant.new(1, 0));

~sampleClickersPatternTwo = Pbind(
\instrument, \sample,
	\delta, Pseq(((1/3!4)++(0.125!2)).lace(32*6) ++ (32*2), inf) * 1/4,
\lpf, Pseq([4000, 10000, 15000, 5000], inf),
\gain, 0.4,
\dur, 1/16,
		\buf, ~brokenGlass.bufnum,
\r, Pseq(1/[16, 8, 2], inf),
\c, 4,
\rate, 1,
\ampBus, ~levelsBeeps.subBus(5).asMap,
\startRatio, Pseq(Array.fill(12, {|i| ((i * pi * 2).asInt % 100) / 100}), inf),
).play(TempoClock.default, quant: Quant.new(1, 24+4));
});

~startBeeps = {
	~startBeepsRoutine.reset();
	~startBeepsRoutine.play();
};
~stopBeeps = {
	~beepOne.stop;
	~highBeep.stop;
	~sampleClickersPattern.stop;
	~sampleClickersPatternTwo.stop;
	~noisePulsesSynth.release;
	~cracklingNoise.release;
	~noisePulseReceiver.disable;
	~noisePulseReceiver.clear;
	~noisePulseReceiver.free;
};
{
	var sliders;
	var maxVal = 4;
	~beepsGui = Window.new("beeps", Rect(420, 500, 400, 400));
	sliders = [
		EZSlider(~beepsGui,  Rect(20, 20, 400, 30),"noise wave",  	ControlSpec(0, maxVal, \amp, 0, 0), 		{|e| ~levelsBeeps.subBus(0).set(e.value)}, 1, unitWidth:30, numberWidth:60,layout:\horz),
		EZSlider(~beepsGui,  Rect(20, 60, 400, 30),"bass", 		 		ControlSpec(0, maxVal, \amp, 0, 0), 		{|e| ~levelsBeeps.subBus(1).set(e.value)}, 1, unitWidth:30, numberWidth:60,layout:\horz),
		EZSlider(~beepsGui,  Rect(20, 100, 400, 30),"Beeps 1",  		ControlSpec(0, maxVal, \amp, 0, 0), 		{|e| ~levelsBeeps.subBus(2).set(e.value)}, 1, unitWidth:30, numberWidth:60,layout:\horz),
		EZSlider(~beepsGui,  Rect(20, 140, 400, 30),"Beeps 2",  		ControlSpec(0, maxVal, \amp, 0, 0), 		{|e| ~levelsBeeps.subBus(3).set(e.value)}, 1, unitWidth:30, numberWidth:60,layout:\horz),
		EZSlider(~beepsGui,  Rect(20, 180, 400, 30),"sample 1",  	ControlSpec(0, maxVal, \amp, 0, 0), 		{|e| ~levelsBeeps.subBus(4).set(e.value)}, 1, unitWidth:30, numberWidth:60,layout:\horz),
		EZSlider(~beepsGui,  Rect(20, 220, 400, 30),"sample 2",  	ControlSpec(0, maxVal, \amp, 0, 0), 		{|e| ~levelsBeeps.subBus(5).set(e.value)}, 1, unitWidth:30, numberWidth:60,layout:\horz)
	];

	if(~songs != nil, {
		var newSong =	LCDSong.new(
			"beeps",
			~startBeeps,
			~stopBeeps,
			~beepsGui,
			60*3,
			0,
			sliders
		);
		newSong.loadSettings;
		~songs.add(newSong);
	});
}.value;
)

// ~startBeeps.value();
// ~stopBeeps.value();