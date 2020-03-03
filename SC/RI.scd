b = Buffer.read(s, "/Users/jildertviet/Music/JildertMusic/Samples/Drums/Drums - Aiff - Mission L'Afrique .17.wav");
b = Buffer.read(s, "/Users/jildertviet/Music/JildertMusic/Samples/Drums/Drums - Fiona Apple - Sleep To Dream.wav");
// c = Buffer.read(s, "/Users/jildertviet/Music/JildertMusic/Samples/Regular/Efterklang - Piramida - Rollende kar fabriek .wav");
b = Buffer.read(s, "/Users/jildertviet/Music/JildertMusic/Samples/Drums/Drums - James Brown - Funky Drummer A0000003.WAV");
// b = Buffer.read(s, "/Users/jildertviet/Music/JildertMusic/Samples/Drums/Drums - The Helio Sequence Live @ KEXP.wav");

(
{
	var buf, out, trig;
	buf = PlayBuf.ar(b.numChannels, b, 1, loop: 1, doneAction: 2);
	// buf = Amplitude.ar(buf);
	buf = buf.round(0.5);
	buf = buf.range(-1, 1);
	trig = Trig.ar(buf, (BufDur.ir(b) / 8));
	out = Klank.ar(`[[14000], nil, 3], trig);
	out = out * 1;
	Out.ar(0, out);
}.play;


{
	var buf, out, trig;
	buf = PlayBuf.ar(b.numChannels, b, 0.5, loop: 1, doneAction: 2);
	// buf = Amplitude.ar(buf);
	buf = buf.round(0.9);
	buf = buf.range(-1, 1);
	trig = Trig.ar(buf);
	out = Klank.ar(`[[5000], nil, 5], trig);
	out = out * 0.03 * LFPulse.kr((1/BufDur.ir(b)/2), 0.25, 1/4);
	out = out * 4;
	Out.ar(0, out);
}.play;

{
	var buf, out, trig, src;
	buf = PlayBuf.ar(b.numChannels, b, 1, loop: 1, doneAction: 2);
	buf = buf.round(0.5);
	buf = Trig.ar(buf, (BufDur.ir(b) / 8));
	buf = Changed.ar(buf);
	out = buf;
	out = Decay.ar(out, LFPulse.kr(1/BufDur.ir(b)).range(0.1, 0.15) / 2);
	out = DelayL.ar(out, 1, BufDur.ir(b) / 8).scope;
	src = HPF.ar(PinkNoise.ar(0.1), 10000);
	out = src * out;
	out = out * 8;
	Out.ar(0, out);
}.play;

{
 	var amp =  0.7 + (SinOsc.kr(1/BufDur.ir(b)/2).range(0, 0.3));
 	var sin = SinOsc.ar(50 + [0, 1], mul: 0.2) * amp;
 	Out.ar(0, sin*0.3);
 }.play;

// {HPF.ar(PlayBuf.ar(c.numChannels, c, 1, Impulse.kr(BufDur.ir(b) / 8).range(-1, 1), startPos: BufFrames.ir(c) * 0.75) * 0.2, 1000)}.play;
)

