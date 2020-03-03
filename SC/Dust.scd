(
{
	var dust = Dust.ar(5).round(1);
	var pan = Pan2.ar(dust, LFDNoise0.kr(4).range(-1, 1));
	var decay = Decay.ar(pan, 0.5);
	decay = BPF.ar(decay, 15000, 0.01, 30);
	Out.ar(0, decay);
}.play;
)

(
{
	var dust = Dust.ar(5).round(1);
	var pan = Pan2.ar(dust, LFDNoise0.kr(4).range(-1, 1));
	var decay = Decay.ar(pan, 0.5);
	var decayRev = BPF.ar(decay, 150, 0.01, 30);
	var pulse = Lag.kr(LFPulse.kr(5), 0.01);
	decay = BPF.ar(decay, 1500, 0.01, 30);
	decay  = decay * pulse;
	decayRev = decayRev * (1-pulse);
	decay = decay + decayRev;
	Out.ar(0, decay);
}.play;
)

(
{
	var dust = Dust.ar(5).round(1);
	var noise = BrownNoise.ar(1!2);
	noise = Trig.ar(dust, 0.025) * noise;
	noise = BPF.ar(noise, 5000, 0.2, 10);
	Out.ar(0, noise);
}.play;
)