n = NetAddr("localhost", 5555);
n.sendMsg("/setMode", 0);

( // All full white
22.do{
	|i|
	n.sendMsg("/", i, 3, 0, 0, 1, 1, 1, 1, 1);
};
)
(
var id = 16.rand;
switch(2,
	0,{
	n.sendMsg("/", id, 3, 0, 0, 1, 1, 0, 0, 1);
},1, {
	n.sendMsg("/", id, 3, 0, 0, 1, 1, 1,0,0);
},2, {
		n.sendMsg("/", id, 3, 0, 0,
			1, 1, 0, 0, 0);
		n.sendMsg("/", id, 3, 0, 0, 1, 1, 1, 0, 0);
});
)

(
var num = 4;
var dcCo = [0.5, 0.8 + 0.09.rand].choose;
var shuffled;
var release;
{
inf.do{
		dcCo = [0.5, 0.8 + 0.09.rand].choose;
		release = dcCo * 200;
		shuffled = Array.fill(3, {15.rand});
~synths.do{|e| e.free};
~synths = Array.newClear(num);
num.do{
	|i|
	~synths[i] = {
		|amp =15|
		var out, trig;
		var noise = PinkNoise.ar(1) + SinOsc.ar([1500,3000].choose);
		var lowFreq = 500 * (1..10).choose + 5000;
		var pulse = LFPulse.kr((1..3).choose * [0.5,1].choose, (1..4).choose/4);
		var bpfFreq = pulse.range(lowFreq, lowFreq*Scale.chromatic.ratios.[5]);
		var bpf = BPF.ar(noise, bpfFreq, 0.1);
		trig = SendTrig.kr(pulse, i);
		bpf = HPF.ar(bpf, 500);
		out = bpf * Lag.kr(LeakDC.kr(pulse, dcCo), [0.05,0.01].choose);
		out = Pan2.ar(out, 2.0.rand-1);
		// out = FreeVerb.ar(out, room: 0.9, damp: 0.8);
		Out.ar(0, out * amp);
}.play;
};
		([4, 8, 8, 16].choose).wait;
};
}.fork;
x.free; x = {SinOsc.ar([60,61], mul: LFPulse.kr(1/4, width: 1/6).range(0.02, 0.2))}.play;

t = 0;
o.free;
o = OSCFunc({ arg msg, time;
	// [time, msg].postln;
	// msg[2].postln;
	switch(msg[2], 0, {
						var addr = [0x24,0x6f,0x28,0xdd,0x48,0x28];
		var end = [101,110,100];
		var numMsg = 1;
				var msg = [2, 2, 255, 100.shortToCharArray[0], 100.shortToCharArray[1]]; // Lag test!
		var b = [0].choose;
		// var msg = [4, 255*0, 255*0.4, 255*1, 255*0.2, b, b, b]; // Draw a black square
		// var msg = [4, 255*0.4, 255*0, 255*0.2, 255*1, 255, 0, 0]; // Draw a black square
		msg = [numMsg] ++ [msg.size] ++ msg;
		// msg.postln;
		// p.putAll(addr ++ msg ++ [addr.size + msg.size + end.size + 1] ++ end);
		n.sendMsg(\test, shuffled.wrapAt(t), 2, 0, 255, 255, 0, 1, 10, release);

	},
	1, {
		n.sendMsg(\test, [4,5].wrapAt(t), 2, 0, 255, 255, 0, 1, 50, release);
		n.sendMsg(\test, [20, 21].wrapAt(t), 2, 0, 255, 255, 0, 1, 50, release);
	},
	2,{
		n.sendMsg(\test, 10, 2, 0, 255, 255, 0, 1, 10, release);
		n.sendMsg(\test, 12, 2, 0, 255, 255, 0, 1, 10, release);
	},
	3, {
		t = t + 1;
		n.sendMsg(\test, [11,13,7,8].wrapAt(t), 2, 0, 255, 255, 0, 1, 50, release);
		n.sendMsg(\test, (17..21).wrapAt(t), 2, 0, 255, 255, 0, 1, 50, release);
	});
},'/tr', s.addr);
)