f = Buffer.read(s, "/Users/jildertviet/Music/JildertMusic/Samples/Regular/Deep Metal Inpact/Metaalkabels.aiff");

(
{
	y.free;
y = {
	|buf=0, numChannels=2, startPos=0, n=100|
	// var phase = Phasor.ar(
	var phase = LFSaw.ar(BufDur.ir(f).reciprocal).range(BufFrames.ir(f) * 0.5, BufFrames.ir(f));
	startPos = BufFrames.ir(f)*0.12;
	phase = Mix.ar(
		Array.fill(
			3,
			{|i| LFPulse.ar((i+1) / 4 * 0.75, iphase: (i/3)*[2,4], mul: ((i+1)/4/4))}
)).range(startPos, startPos + BufFrames.ir(f) * 0.1)
	+ LFSaw.ar(BufDur.ir(f).reciprocal*n*1).range(0, BufFrames.ir(f)*(1/n));
	phase = BufRd.ar(2, f.bufnum, phase);
	phase = LPF.ar(phase, Lag.kr(EnvGen.kr(Env.step([1000, 500, LFPulse.kr(0.25, width: 0.25).range(1000, 5000), 100], (0.5!4), 3, 0), 1), 0.05));
		// JPverb.ar(phase) + phase;
	// phase = Lag.kr(LFPulse.kr(1, width: LFPulse.kr(1/4).range(0.75))) * phase;
}.play(s, [buf: f]);
}.fork(t, 1);
)

(
y.free;
x = {
	|buf=0, numChannels=2, startPos=0, n=250|
	// var phase = Phasor.ar(
	var phase = LFSaw.ar(BufDur.ir(f).reciprocal).range(0, BufFrames.ir(f));
	startPos = BufFrames.ir(f)*[0.25, 0.255];
	phase = Mix.ar(
		Array.fill(
			3,
			{|i| LFPulse.ar((i+1) / 4 * 0.75, iphase: (i/3)*[3,4], mul: ((i+1)/4/8))}
)).range(startPos, startPos + BufFrames.ir(f) * 0.05)
	+ LFSaw.ar(BufDur.ir(f).reciprocal*n*1).range(0, BufFrames.ir(f)*(1/n));
	phase = BufRd.ar(2, f.bufnum, phase);
	phase = LPF.ar(phase, Lag.kr(EnvGen.kr(Env.step([1000, 500, LFPulse.kr(0.125, width: 0.25).range(1000, 10000), 100], (0.5!4), 3, 0), 1), 0.05));
	phase = HPF.ar(phase, 100);
	// JPverb.ar(phase) + phase;
	// phase = Lag.kr(LFPulse.kr(1, width: LFPulse.kr(1/4).range(0.75))) * phase;
}.play(s, [buf: f]);

{
	// LFPulse.kr([4,3]) * (HPF.ar(WhiteNoise.ar(0.005), 10000) + GrayNoise.ar(LFPulse.kr(0.25, width: 0.75).range(0.01, 0.005)));
}.play;
)

x.free;