Engine_Aviarym : CroneEngine {
    var <buf;
    var <synth;
    
    *new { arg context, doneCallback;
        ^super.new(context, doneCallback);
    }
    
    alloc {
        // Create a buffer for the sample
        buf = Buffer.new(context.server);
        
        // Define the sampler synth
        SynthDef(\aviarym_sampler, { arg out=0, bufnum=0, rate=1, amp=0.5, pan=0;
            var sig = PlayBuf.ar(1, bufnum, rate, doneAction: 2);
            sig = sig * amp;
            sig = Pan2.ar(sig, pan);
            Out.ar(out, sig);
        }).add;
        
        // Wait for the synthdef to be added
        context.server.sync;
        
        // Create the synth
        synth = Synth.new(\aviarym_sampler, [
            \out, context.out_b.index,
            \bufnum, buf.bufnum,
            \rate, 1,
            \amp, 0.5,
            \pan, 0
        ], context.xg);
        
        // Add commands
        this.addCommand("load", "s", { arg msg;
            buf.free;
            buf = Buffer.read(context.server, msg[1]);
        });
        
        this.addCommand("play", "f", { arg msg;
            var rate = msg[1];
            synth.set(\rate, rate);
            synth.run(true);
        });
        
        this.addCommand("amp", "f", { arg msg;
            synth.set(\amp, msg[1]);
        });
        
        this.addCommand("pan", "f", { arg msg;
            synth.set(\pan, msg[1]);
        });
    }
    
    free {
        buf.free;
        synth.free;
    }
} 