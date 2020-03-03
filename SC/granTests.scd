b = Buffer.read(s, "/Users/jildertviet/Music/JildertMusic/synth.wav");
b = Buffer.readChannel(s,"/Users/jildertviet/Music/JildertMusic/Samples/Keys/pianoVoices/0.wav", channels: 1);

(
~gran.free;
~gran = {
	var centerPos = b.duration * 0.7 + LFDNoise1.kr(0.5).abs.range(0, 0.005);
	var dur = 0.7;
	var pan = 0;
	var amp = SinOsc.kr(1/4 + 1.0.rand, mul: 0.3).abs + 0.7;
	var rate = [1,1.01,2,0.5,3] * Lag.kr(LFPulse.kr(LFDNoise0.kr(1/4).range(1, 0.25)/3).scope.range(0.5, 1), 0.001);
	var freq = LFDNoise3.kr(1/12).abs.range(5, 20);
	var out, env;
	amp = amp * [0.5, 0.5, 0.05, 0.2, 0.1];
	out = TGrains.ar(2, Impulse.ar(freq), b, rate, centerPos, dur, pan, amp, 0);
	out = CombC.ar(out, 1/2, 1/4, LFDNoise1.kr(1/4).range(0.1, 3)) + out;
	out = Mix.ar(out);
	out = LPF.ar(out, LFDNoise1.kr(1/5).range(4000,10000));
	out = HPF.ar(HPF.ar(out, 200);, 200);
	out = out * 6;
	env = EnvGate.new(1, NamedControl.kr("gate", 1), 10) * EnvGen.kr(Env.adsr(5));
	// out = out + (SinOsc.ar(30, mul: 0.4) * LFPulse.kr(3));
	Out.ar(0, out * env);
}.play();
~gran.set(\fadeTime, 10);
)

~gran.release

s.makeGui()
s