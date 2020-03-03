(
~levelsKlingel = Bus.alloc(\control, s, 2).setn([0.5, 1]);
~klingelSample = Buffer.readChannel(s, "/Users/jildertviet/Music/JildertMusic/Spul/Sliced Beats/untitled_Insert 5_45.wav", channels: 0);
SynthDef(\lowNoise, {
	|at=1, sus=1, rel=1, delTime=0.001, freq= 100, freqMax=1000, pulseFreq=10, lfOffset=100, lfAt=1, bpfFreq=100, amp=1|
	var out, src, env, pulse, filt, lpf, lpfFreq, sin;
	env = Env.linen(at, sus, rel, curve: -1);
	env = EnvGen.kr(env, doneAction: 2);
	src = WhiteNoise.ar(1);
	pulse = LFPulse.ar(pulseFreq*LFDNoise1.kr(2, 0.5, 1));
	pulse = Lag.ar(pulse, LFDNoise1.kr(2, 0.1, 0.4));
	src = src * pulse;
	src = src + Dust.ar(5);
	src = src * env;
	filt = CombL.ar(src, 0.2, delTime, 1);
	filt = filt * Saw.ar(freq);
	sin = Saw.ar(freq/4, 0.5);
	sin = sin * env;
	filt = filt + (sin*0.01);
	lpfFreq = Env.linen(lfAt, sus, rel);
	lpfFreq = EnvGen.kr(lpfFreq, levelScale: lfOffset, levelBias: freqMax);
	lpf = LPF.ar(filt, lpfFreq);

	lpf = BPF.ar(lpf, bpfFreq, 0.001);
	lpf = Normalizer.ar(lpf, 1, 0.01);
	lpf = lpf * env;

	out = Out.ar([0,1], lpf * amp);
}).add;

SynthDef(\playBufKling, { |bufnum = 0, amp=0.5, gate=1, attack=0.000001, release=1, bpfFreq=#[1000, 2000, 500, 2999]|
	// var bpfFreq = [400, 200, 100, 50];
	var env = EnvGen.kr(Env.asr(attack, 1.0, release), gate, doneAction: 2);
	var bpfFreqs = bpfFreq;
	var out;
	out = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum) * (1/[2,4,8,2]) * [1, 1].choose, loop: 1, doneAction: Done.freeSelf);
	out = out * SinOsc.kr(1/[3,2,4,1].rotate(10.rand) * 0.5, mul: 0.25, add: 0.75);
	// out = BPF.ar(out, bpfFreq);
	out = DynKlank.ar(`[bpfFreqs, nil, 0.1], out);
	out = HPF.ar(out, 1600);
	out = Mix.ar(out);
	Out.ar([0,1], out * amp * env);
}).add;

~triggerLowNoises = Routine.new({
	10.wait;
	inf.do{
		var attack = [1,0.1].choose * 4;
		var sustain = 3;
		var release = [7, 5].choose;
		var delayTimeEvent = [10, 1, 50].choose;
		var sizeRange = [10, 50, 100].choose;
		Synth.new(\lowNoise, [
			at: attack,
			sus: sustain,
			rel: release,
			delTime: 0.03 * [1, 1.5, 1.25].choose,
			freq: [100].choose,
			freqMax: [1000,1000].choose,
			pulseFreq: [10,4,15,20].choose * 2,
			lfOffset: [200,4000].choose,
			lfAt: [1,5,3].choose,
			bpfFreq: 50,
			amp: ~levelsKlingel.subBus(1).asMap
		]);
		25.do{
			|i|
			if(i != ~currentLighted, {
				~lcd.doEnv(i, 255, [attack, sustain, release * rand(0.95, 1.05)] * 1000);
				0.005.wait;
				~lcd.eventExpRand(i, lifeTime: (attack+sustain+release)*1000, delayTimeEvent: delayTimeEvent, sizeRange: sizeRange);
				0.005.wait;
			});
		};
		(12+[3,5,10].choose).wait;
	}
});

~currentLighted = 0;
~walk = Routine.new({
	inf.do{
		~currentLighted = 25.rand;
		~lcd.eventRect(~currentLighted, lifeTime: 3000, speedX: 0, speedY: 0);
		~lcd.doEnv(~currentLighted, 255);
		1.5.wait;
	};
});

~startKlingel = {
	// init LCD
	~lcd.setVisualizerMode(0);
	~lcd.fillRect(-1);
	if(~klings != nil, {
		~klings.set(\release, 5);
		~klings.release;
	});
	~klings = Synth.new(\playBufKling, [bufnum: ~klingelSample, bpfFreq: [1000, 2000, 500, 2999].rotate(4.rand) * [0.5].choose, amp: ~levelsKlingel.subBus(0).asMap]);
	~triggerLowNoises.reset;
	~triggerLowNoises.play;
	~walk.reset();
	~walk.play;
};

~stopKlingel = {
	~klings.set(\release, 20);
	~klings.release;
	~triggerLowNoises.stop;
	~walk.stop
};
{
	var sliders;
	~klingelGui = Window.new("klingels", Rect(420, 500, 400, 400));
	sliders = [
		EZSlider(~klingelGui,  Rect(20, 20, 400, 30),"klingelSample",  ControlSpec(0, 4, \amp, 0, 0), 		{|e| ~levelsKlingel.subBus(0).set(e.value)}, 0.5, unitWidth:30, numberWidth:60,layout:\horz),
		EZSlider(~klingelGui,  Rect(20, 60, 400, 30),"low",  ControlSpec(0, 4, \amp, 0, 0), 				{|e| ~levelsKlingel.subBus(1).set(e.value)}, 1, unitWidth:30, numberWidth:60,layout:\horz)
	];

	if(~songs != nil, {
		var newSong = LCDSong.new(
			"klingel",
			~startKlingel,
			~stopKlingel,
			~klingelGui,
			60*3,
			0,
			sliders
		);
		newSong.loadSettings;
		~songs.add(newSong);
	});
}.value;
)

// ~startKlingel.value;
// ~stopKlingel.value;