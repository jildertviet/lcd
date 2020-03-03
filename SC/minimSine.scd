(
~levelsMinimSine = Bus.alloc(\control, s, 4).setn(1!4);

~initVisuals = {
	~v.killAll;
	~vf = JVecField.new("nonCamFront");
	~vf.create();
	~vf.setSpeed(0.007);
	~vf.setDensity([128, 80]);
	~vf.setSize([1280, 800]);
	~vf.setColor([255, 0, 0, 255]);
	~vf.setSourceMode("perlin");
	~vf.setComplexity(30);
};
~initLCDs = {
	{
		~lcd.setVisualizerMode(1); // Stream
		~lcd.setVal(-1, 0);
		2.do{ // Double check!
			0.5.wait;
			~lcd.fillRect(-1, r:255, g:0, b:0);
		}
	}.fork;
};

SynthDef(\dust, {
	|gate=1, attack=10, release=10, amp=1|
	var env = EnvGen.kr(Env.asr(attack, 1, release), gate, doneAction: 2);
	var dustOne = HPF.ar(Dust.ar(LFPulse.kr(0.5).range(1, 10))!2, 1000);
	var dustTwo = 	HPF.ar(Dust.ar(LFPulse.kr(1).range(5, 10))!2, 10000);
	var out = dustOne + dustTwo;
	Out.ar(0, out * env * amp);
}).add;

SynthDef(\crackle,{
	|hpf=2000, amp=1, gate=1, attack=5, release=10, ampBus=1|
	var env = EnvGen.kr(Env.asr(attack, 1, release), gate, doneAction: 2);
	var noise = Crackle.ar(1.95, 0.5)!2;
	noise = HPF.ar(noise, hpf);
	Out.ar(0, noise * amp * env * ampBus);
}, [0.2, 0.2]).add;

SynthDef(\noiseTicks, {
	|amp=1|
	var width = [1/32, 1/16] * LFPulse.kr(1/16).range(0.5, 1.5) * 0.5;
	var pulse = LFPulse.kr(1/8, 1/16, width: width);
	var sendTrig = SendTrig.kr(pulse[0], 0, width[0]);
	var sendTrigRight = SendTrig.kr(pulse[1], 1, width[1]);
	var noise = HPF.ar(BrownNoise.ar(0.1), 1000);
	Out.ar(0, pulse * noise * amp);
}).add;

SynthDef(\sinStack, {
	|gate=1, release=0.5, amp=1, freq=#[300, 302, 332], lfFreq= 0.5|
	var env, output;
	env = EnvGen.kr(Env.asr(0.1, 1, release), gate, doneAction: 2);
	output = Mix.ar(
		Array.fill(freq.size,{
			|i|
			SinOsc.ar(freq.wrapAt(i) * [1, LFPulse.kr(1/3, 1/4, width: 1/4).range(0.75, 0.25), Scale.minor.ratios[1]],
				Rand(0, 1) * 2pi,
				Array.fill(freq.size, {LFDNoise1.kr(lfFreq * 3).abs.range(0.005, [0.1, 0.2, 0.2].wrapAt(i))})
			) * 0.4
		});
	)!2 * 0.75;
	Out.ar(0, output * env * amp);
}).add;

~sinStrackRoutine = Routine({
	inf.do{
		var index = 3.rand;
		var freq = #[300, 302, 332] + [[0, 0, 100], [0, 0, 0], [50, 0, 0]].at(index);
		~vf.setSpeed([0.007, 0.003, 0.01].at(index));
		~vf.setComplexity([20,30,40].at(index));
		~sinStack.release();
		~sinStack = Synth(\sinStack, [freq: freq, lfFreq: [0.1, 0.5].choose, amp: ~levelsMinimSine.subBus(3).asMap]);
		8.wait;
	}
});

~startMinimSine = {
	{
		~initLCDs.value();
		0.5.wait;
		~initVisuals.value(); // Create vecField
		~crackleOne.free; ~crackleOne = Synth(\crackle, [ampBus: ~levelsMinimSine.subBus(0).asMap]);
		~crackleTwo.free; ~crackleTwo = Synth(\crackle, [ampBus: ~levelsMinimSine.subBus(0).asMap]);
		~crackleMod.stop;
		~crackleMod = Pbind(*[
			type: \set,
			id: [~crackleOne.nodeID, ~crackleTwo.nodeID],
			args: #[\hpf, \amp],
			hpf: Pseq([1, 4], inf) * [1000,2000,3000,2000,1000],
			amp: Pseq([0.1, 0.5, 0.25, 1.0], inf) * 0.6,
			delta: Pseq([1, 0.5, 2, 0.25, 1], inf) * 0.125
		]).play;

		~dust = Synth(\dust, [amp: ~levelsMinimSine.subBus(1).asMap]);
		~noiseTicks = Synth.new(\noiseTicks, [amp: ~levelsMinimSine.subBus(2).asMap]);
		~brownNoiseTrig.free;
		~brownNoiseTrig = OSCFunc({ arg msg, time;
			[time, msg].postln;
			if(msg[2] == 0, {
				// Left noise
				j = JRectangle.new("nonCamFront");
				j.create();
				j.setLoc([[0], -100]);
				j.setSize([80, 1000]);
				j.setColor([255, 255, 255, 255]);
				j.addEnv(times: [1, msg[3]*2000, msg[3]*500], kill: true);
			}, {
				// Right noise
				j = JRectangle.new("nonCamFront");
				j.create();
				j.setLoc([820, -100]);
				j.setSize([80, 1000]);
				j.setColor([255, 255, 255, 255]);
				j.addEnv(times: [1, msg[3]*2000, msg[3]*500], kill: true);
			});
		},'/tr', s.addr);

		~sinStrackRoutine.reset();
		~sinStrackRoutine.play();
		~lcd.stream();
	}.fork;
};
~stopMinimSine = {
	~crackleOne.release();
	~crackleTwo.release();
	~crackleMod.stop;
	~dust.release();
	~noiseTicks.free;
	~sinStrackRoutine.stop;
	~sinStack.set(\release, 5);
	~sinStack.release();
	~brownNoiseTrig.disable;
	~brownNoiseTrig.clear;
	~brownNoiseTrig.free;
	~lcd.stopStream;
	{0.2.wait; ~lcd.setValLag(-1, 0, 5000);}.fork;
};
{
	var window = ~minimSineGui = Window.new("minimSine", Rect(420, 500, 400, 400));
	var maxVal = 4;
	var sliders = [
		EZSlider(~minimSineGui,  Rect(20, 20, 400, 30),"cracle amp",  ControlSpec(0, maxVal, \amp, 0, 0), 		{|e| ~levelsMinimSine.subBus(0).set(e.value)}, 1, unitWidth:30, numberWidth:60,layout:\horz),
		EZSlider(~minimSineGui,  Rect(20, 60, 400, 30),"dust",  ControlSpec(0, maxVal, \amp, 0, 0), 				{|e| ~levelsMinimSine.subBus(1).set(e.value)}, 1, unitWidth:30, numberWidth:60,layout:\horz),
		EZSlider(~minimSineGui,  Rect(20, 100, 400, 30),"noiseTicks",  ControlSpec(0, maxVal, \amp, 0, 0), 	{|e| ~levelsMinimSine.subBus(2).set(e.value)}, 1, unitWidth:30, numberWidth:60,layout:\horz),
		EZSlider(~minimSineGui,  Rect(20, 140, 400, 30),"sineStack",  ControlSpec(0, maxVal, \amp, 0, 0), 	{|e| ~levelsMinimSine.subBus(3).set(e.value)}, 1, unitWidth:30, numberWidth:60,layout:\horz)
	];

	if(~songs != nil, {
		var newSong =
		LCDSong.new(
			"minimSine",
			~startMinimSine,
			~stopMinimSine,
			~minimSineGui,
			60*3,
			0,
			sliders
		);
		newSong.loadSettings;
		~songs.add(newSong);
	});
}.value;
)

// ~startMinimSine.value();
// ~stopMinimSine.value();

// ~vf.setSpeed(0.003);
// ~vf.setComplexity([20,30,40].choose);