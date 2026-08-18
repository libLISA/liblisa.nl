#import "../theme.typ": *

= Evaluation <sem86:sec:results>

In this Section, we evaluate three aspects of #sem86.
First, we construct a toy malware sample and confirm #sem86 is able to identify where this sample uses undefined behavior to detect whether it is running on an emulated CPU.
Second, we boot several real-world operating systems to evaluate hardware support.
Finally, we evaluate the performance of #sem86 by comparing it with QEMU and Bochs.

== CPU-specific semantics
CPU-specific behavior has not been well-researched.
To the best of our knowledge, there exists no comprehensive overview of differences in undefined behavior, nor analysis of real-world usage of such differences for emulator detection.
Because of this, it is difficult to find real malware samples (ab)using CPU-specific behavior.

Instead, we evaluate #sem86's ability to use different semantics
by constructing a toy malware sample that relies on CPU-specific behavior.
Our toy malware sample determines whether it is running inside an emulator by executing the #tt[IMUL] instruction,
and checking the value that is stored in the zero flag (ZF) afterwards.
The source code of our toy malware sample is shown in @sem86:fig:toy-malware.

#html-compatible-figure([
  ```c
  int APIENTRY WinMain(...) 
      int result = 0;
      int a = 15;
      int b = 0;

      __asm {
          xor result, 1
          mov eax, a
          mov ecx, b
          imul eax, ecx
          jnz done
          mov result, 0
  done:
      };

      if (result) {
          MessageBox(NULL, "Deleting C drive", "", 0);
      } else {
          MessageBox(NULL, "Analysis attempt detected.", "", 0);
      }
      
      return 0;
  }
  ```
], caption: [
    Our toy malware sample. It forces ZF=0 by performing an #tt[XOR] that produces a non-zero result, and then executes an #tt[IMUL] that will produce a zero result. Finally, it checks whether the #tt[IMUL] instruction has modified the ZF. This is then used to show one of two message boxes: one message box represents malicious behavior, while the other message box represents silently exiting. The sample was compiled under Windows 98 using Visual Studio 6.0.
], label: <sem86:fig:toy-malware>)

The ZF is undefined for the #tt[IMUL] instruction, and is often implemented differently both in actual CPUs as well as emulators.
Bochs currently implements the ZF by setting it to 1 if the result was zero, and setting it to 0 otherwise.
Although modern CPUs implement various different behaviors, for the purposes of this experiment we assume that a real CPU would not modify ZF, which appears to have been common at the time when this technique was detected~@imulvmdetection.

We generated two different semantics: one where #tt[IMUL] sets the ZF to the normal result, which behaves like Bochs, and one where #tt[IMUL] does not modify the ZF.
Starting #sem86 with the semantics where #tt[IMUL] behaves like Bochs, shows the "Analysis attempt detected" message, while starting it with the semantics where #tt[IMUL] does not behave like Bochs correctly shows the "Deleting C drive" message.

In order to evaluate bisection, we set the toy malware sample to automatically start upon boot, and then ran a bisection on the display output of the emulator after 400 million executed instructions.
For real malware, other characteristics such as file system contents or network access attempts could be used instead of the display output.
The bisection was able to automatically identify the #tt[IMUL] instruction as being the instruction that determines which message box is shown.

== Booting real-world operating systems
#sem86 implements all hardware required to boot x86 operating systems.
We evaluated this by booting Windows 98, Windows XP and Windows 7.
We were able to boot all of these operating systems,
as depicted in @sem86:fig:screenshots.

#html-compatible-multifigure(
  columns: (1fr, 1fr, 1fr),
  (figure([
    #image("../imgs/w98-small.png")
  ], caption: [ Windows 98 SE. ]), none),
  (figure([
    #image("../imgs/wxp-phone-small.png")
  ], caption: [ Windows XP running in #sem86 on an Android phone. ]), none),
  (figure([
    #image("../imgs/w7-small.png")
  ], caption: [ Windows 7. ]), none),
  caption: [
    Various operating systems running in #sem86.
], label: <sem86:fig:screenshots>)

The ES1370 sound card and the NE2000 networking card cannot be used under Windows 7.
While these work on Windows 98 and XP, no drivers are available for Windows 7.
In order to enable sound and networking for Windows 7 and newer,
more modern hardware needs to be implemented.

To demonstrate that #sem86's implementation is portable, we have ported it to Android.
We tested this on an Android phone that has 8~GiB of RAM.
While it is fully functional, it can sometimes, crash due to the memory usage of LLVM, which can reach 4-5~GiB during JIT compilation of some instruction sequences.

== Performance
We have evaluated the performance of #sem86 using CPUMark'99 running on Windows XP.
This is a single-threaded benchmark that evaluates integer performance of CPUs,
which was commonly used to evaluate CPU performance in the 90s.
After completing the benchmark, it displays a single score that summarizes CPU performance.
The results are presented in @sem86:tbl:benchmark.
We also list how many million instructions were executed per second (MIPS) during the benchmark.

#html-compatible-figure([
  #table(
    columns: (auto, auto, auto),
    align: (x, y) => if x == 0 { left } else { center },
    table.header(
      [Emulator], [Score], [MIPS],
    ),
    [QEMU (10.1.0)], [$89.8$], [-], 
    [Bochs (3.0)], [$19.9$], [$74.31$],
    [#sem86], [$38.1$], [$192.7$],
  )
], caption: [
     The CPUMark'99 score of various emulators, as measured on an AMD 3900X host CPU. The score is the best of 5 runs. MIPS listed is the highest reached during all runs. Since QEMU does not report MIPS, this column is left blank.
], label: <sem86:tbl:benchmark>)

We compare against QEMU and Bochs, because they are at opposite ends of the optimization spectrum:
Bochs is purely an interpreter, and does not use any JIT optimization techniques for portability reasons.
On the other hand, QEMU uses bespoke JIT code generation to translate guest instruction traces into native code, and has been heavily optimized for performance.

We believe the difference in performance between #sem86 and QEMU is mostly due to JIT code generation quality.
QEMU uses a bespoke JIT, while we rely on off-the-shelf LLVM.
LLVM is a general-purpose compiler library, which is not geared specifically to emulators.
The code generated by LLVM is likely of lower quality than that generated by QEMU.
For example, because we do not have full control over code generation, LLVM sometimes generates larger function preludes that preserve more registers on the stack.
While this would likely benefit normal programs, it degrades performance when functions are called hundreds of millions of times per second.

Additionally, QEMU performs basic block linking, where jumps to the next basic block are inlined directly into the block.
This avoids the overhead of returning to the execution loop, and looking up the next basic block in the cache data structures.
While #sem86 also does this for basic blocks within the same page, we have not implemented this for jumps between different pages.
