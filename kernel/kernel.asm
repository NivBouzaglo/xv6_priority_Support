
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8c013103          	ld	sp,-1856(sp) # 800088c0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	8ce70713          	addi	a4,a4,-1842 # 80008920 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	21c78793          	addi	a5,a5,540 # 80006280 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdb86f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dca78793          	addi	a5,a5,-566 # 80000e78 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	3e8080e7          	jalr	1000(ra) # 80002514 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8d650513          	addi	a0,a0,-1834 # 80010a60 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8c648493          	addi	s1,s1,-1850 # 80010a60 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	95690913          	addi	s2,s2,-1706 # 80010af8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7f4080e7          	jalr	2036(ra) # 800019b4 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	156080e7          	jalr	342(ra) # 8000231e <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	e8e080e7          	jalr	-370(ra) # 80002064 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	2ac080e7          	jalr	684(ra) # 800024be <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	83a50513          	addi	a0,a0,-1990 # 80010a60 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	82450513          	addi	a0,a0,-2012 # 80010a60 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	88f72323          	sw	a5,-1914(a4) # 80010af8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	79450513          	addi	a0,a0,1940 # 80010a60 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	278080e7          	jalr	632(ra) # 8000256a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	76650513          	addi	a0,a0,1894 # 80010a60 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	74270713          	addi	a4,a4,1858 # 80010a60 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	71878793          	addi	a5,a5,1816 # 80010a60 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7827a783          	lw	a5,1922(a5) # 80010af8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6d670713          	addi	a4,a4,1750 # 80010a60 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6c648493          	addi	s1,s1,1734 # 80010a60 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	68a70713          	addi	a4,a4,1674 # 80010a60 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72a23          	sw	a5,1812(a4) # 80010b00 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	64e78793          	addi	a5,a5,1614 # 80010a60 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6cc7a323          	sw	a2,1734(a5) # 80010afc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6ba50513          	addi	a0,a0,1722 # 80010af8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c82080e7          	jalr	-894(ra) # 800020c8 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	60050513          	addi	a0,a0,1536 # 80010a60 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	98078793          	addi	a5,a5,-1664 # 80021df8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	5c07ab23          	sw	zero,1494(a5) # 80010b20 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	36f72123          	sw	a5,866(a4) # 800088e0 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	566dad83          	lw	s11,1382(s11) # 80010b20 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	51050513          	addi	a0,a0,1296 # 80010b08 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	3b250513          	addi	a0,a0,946 # 80010b08 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	39648493          	addi	s1,s1,918 # 80010b08 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3c2080e7          	jalr	962(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	35650513          	addi	a0,a0,854 # 80010b28 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	36c080e7          	jalr	876(ra) # 80000b46 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	394080e7          	jalr	916(ra) # 80000b8a <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	0e27a783          	lw	a5,226(a5) # 800088e0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	406080e7          	jalr	1030(ra) # 80000c2a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	0b27b783          	ld	a5,178(a5) # 800088e8 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	0b273703          	ld	a4,178(a4) # 800088f0 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	2c8a0a13          	addi	s4,s4,712 # 80010b28 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	08048493          	addi	s1,s1,128 # 800088e8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	08098993          	addi	s3,s3,128 # 800088f0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	836080e7          	jalr	-1994(ra) # 800020c8 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	25a50513          	addi	a0,a0,602 # 80010b28 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	0027a783          	lw	a5,2(a5) # 800088e0 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	00873703          	ld	a4,8(a4) # 800088f0 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	ff87b783          	ld	a5,-8(a5) # 800088e8 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	22c98993          	addi	s3,s3,556 # 80010b28 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	fe448493          	addi	s1,s1,-28 # 800088e8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	fe490913          	addi	s2,s2,-28 # 800088f0 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00001097          	auipc	ra,0x1
    80000920:	748080e7          	jalr	1864(ra) # 80002064 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	1f648493          	addi	s1,s1,502 # 80010b28 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	fae7b523          	sd	a4,-86(a5) # 800088f0 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	16c48493          	addi	s1,s1,364 # 80010b28 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00022797          	auipc	a5,0x22
    80000a02:	59278793          	addi	a5,a5,1426 # 80022f90 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	14290913          	addi	s2,s2,322 # 80010b60 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	0a650513          	addi	a0,a0,166 # 80010b60 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00022517          	auipc	a0,0x22
    80000ad2:	4c250513          	addi	a0,a0,1218 # 80022f90 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	07048493          	addi	s1,s1,112 # 80010b60 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	05850513          	addi	a0,a0,88 # 80010b60 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	02c50513          	addi	a0,a0,44 # 80010b60 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e28080e7          	jalr	-472(ra) # 80001998 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	df6080e7          	jalr	-522(ra) # 80001998 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	dea080e7          	jalr	-534(ra) # 80001998 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dd2080e7          	jalr	-558(ra) # 80001998 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d92080e7          	jalr	-622(ra) # 80001998 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d66080e7          	jalr	-666(ra) # 80001998 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	fff6c793          	not	a5,a3
    80000e0c:	9fb9                	addw	a5,a5,a4
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b08080e7          	jalr	-1272(ra) # 80001988 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a7070713          	addi	a4,a4,-1424 # 800088f8 <started>
  if(cpuid() == 0){
    80000e90:	c539                	beqz	a0,80000ede <main+0x66>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	aec080e7          	jalr	-1300(ra) # 80001988 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0e0080e7          	jalr	224(ra) # 80000f96 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	cfc080e7          	jalr	-772(ra) # 80002bba <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	3fa080e7          	jalr	1018(ra) # 800062c0 <plicinithart>
  }
  scheduler();
    80000ece:	00002097          	auipc	ra,0x2
    80000ed2:	af6080e7          	jalr	-1290(ra) # 800029c4 <scheduler>
}
    80000ed6:	60a2                	ld	ra,8(sp)
    80000ed8:	6402                	ld	s0,0(sp)
    80000eda:	0141                	addi	sp,sp,16
    80000edc:	8082                	ret
    consoleinit();
    80000ede:	fffff097          	auipc	ra,0xfffff
    80000ee2:	572080e7          	jalr	1394(ra) # 80000450 <consoleinit>
    printfinit();
    80000ee6:	00000097          	auipc	ra,0x0
    80000eea:	882080e7          	jalr	-1918(ra) # 80000768 <printfinit>
    printf("\n");
    80000eee:	00007517          	auipc	a0,0x7
    80000ef2:	1da50513          	addi	a0,a0,474 # 800080c8 <digits+0x88>
    80000ef6:	fffff097          	auipc	ra,0xfffff
    80000efa:	692080e7          	jalr	1682(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000efe:	00007517          	auipc	a0,0x7
    80000f02:	1a250513          	addi	a0,a0,418 # 800080a0 <digits+0x60>
    80000f06:	fffff097          	auipc	ra,0xfffff
    80000f0a:	682080e7          	jalr	1666(ra) # 80000588 <printf>
    printf("\n");
    80000f0e:	00007517          	auipc	a0,0x7
    80000f12:	1ba50513          	addi	a0,a0,442 # 800080c8 <digits+0x88>
    80000f16:	fffff097          	auipc	ra,0xfffff
    80000f1a:	672080e7          	jalr	1650(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	b8c080e7          	jalr	-1140(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	326080e7          	jalr	806(ra) # 8000124c <kvminit>
    kvminithart();   // turn on paging
    80000f2e:	00000097          	auipc	ra,0x0
    80000f32:	068080e7          	jalr	104(ra) # 80000f96 <kvminithart>
    procinit();      // process table
    80000f36:	00001097          	auipc	ra,0x1
    80000f3a:	99e080e7          	jalr	-1634(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	c54080e7          	jalr	-940(ra) # 80002b92 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f46:	00002097          	auipc	ra,0x2
    80000f4a:	c74080e7          	jalr	-908(ra) # 80002bba <trapinithart>
    plicinit();      // set up interrupt controller
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	35c080e7          	jalr	860(ra) # 800062aa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f56:	00005097          	auipc	ra,0x5
    80000f5a:	36a080e7          	jalr	874(ra) # 800062c0 <plicinithart>
    binit();         // buffer cache
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	510080e7          	jalr	1296(ra) # 8000346e <binit>
    iinit();         // inode table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	bb4080e7          	jalr	-1100(ra) # 80003b1a <iinit>
    fileinit();      // file table
    80000f6e:	00004097          	auipc	ra,0x4
    80000f72:	b52080e7          	jalr	-1198(ra) # 80004ac0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f76:	00005097          	auipc	ra,0x5
    80000f7a:	452080e7          	jalr	1106(ra) # 800063c8 <virtio_disk_init>
    userinit();      // first user process
    80000f7e:	00001097          	auipc	ra,0x1
    80000f82:	d24080e7          	jalr	-732(ra) # 80001ca2 <userinit>
    __sync_synchronize();
    80000f86:	0ff0000f          	fence
    started = 1;
    80000f8a:	4785                	li	a5,1
    80000f8c:	00008717          	auipc	a4,0x8
    80000f90:	96f72623          	sw	a5,-1684(a4) # 800088f8 <started>
    80000f94:	bf2d                	j	80000ece <main+0x56>

0000000080000f96 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f96:	1141                	addi	sp,sp,-16
    80000f98:	e422                	sd	s0,8(sp)
    80000f9a:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f9c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fa0:	00008797          	auipc	a5,0x8
    80000fa4:	9607b783          	ld	a5,-1696(a5) # 80008900 <kernel_pagetable>
    80000fa8:	83b1                	srli	a5,a5,0xc
    80000faa:	577d                	li	a4,-1
    80000fac:	177e                	slli	a4,a4,0x3f
    80000fae:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fb0:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fb4:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb8:	6422                	ld	s0,8(sp)
    80000fba:	0141                	addi	sp,sp,16
    80000fbc:	8082                	ret

0000000080000fbe <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fbe:	7139                	addi	sp,sp,-64
    80000fc0:	fc06                	sd	ra,56(sp)
    80000fc2:	f822                	sd	s0,48(sp)
    80000fc4:	f426                	sd	s1,40(sp)
    80000fc6:	f04a                	sd	s2,32(sp)
    80000fc8:	ec4e                	sd	s3,24(sp)
    80000fca:	e852                	sd	s4,16(sp)
    80000fcc:	e456                	sd	s5,8(sp)
    80000fce:	e05a                	sd	s6,0(sp)
    80000fd0:	0080                	addi	s0,sp,64
    80000fd2:	84aa                	mv	s1,a0
    80000fd4:	89ae                	mv	s3,a1
    80000fd6:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd8:	57fd                	li	a5,-1
    80000fda:	83e9                	srli	a5,a5,0x1a
    80000fdc:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fde:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fe0:	04b7f263          	bgeu	a5,a1,80001024 <walk+0x66>
    panic("walk");
    80000fe4:	00007517          	auipc	a0,0x7
    80000fe8:	0ec50513          	addi	a0,a0,236 # 800080d0 <digits+0x90>
    80000fec:	fffff097          	auipc	ra,0xfffff
    80000ff0:	552080e7          	jalr	1362(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ff4:	060a8663          	beqz	s5,80001060 <walk+0xa2>
    80000ff8:	00000097          	auipc	ra,0x0
    80000ffc:	aee080e7          	jalr	-1298(ra) # 80000ae6 <kalloc>
    80001000:	84aa                	mv	s1,a0
    80001002:	c529                	beqz	a0,8000104c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001004:	6605                	lui	a2,0x1
    80001006:	4581                	li	a1,0
    80001008:	00000097          	auipc	ra,0x0
    8000100c:	cca080e7          	jalr	-822(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001010:	00c4d793          	srli	a5,s1,0xc
    80001014:	07aa                	slli	a5,a5,0xa
    80001016:	0017e793          	ori	a5,a5,1
    8000101a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000101e:	3a5d                	addiw	s4,s4,-9
    80001020:	036a0063          	beq	s4,s6,80001040 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001024:	0149d933          	srl	s2,s3,s4
    80001028:	1ff97913          	andi	s2,s2,511
    8000102c:	090e                	slli	s2,s2,0x3
    8000102e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001030:	00093483          	ld	s1,0(s2)
    80001034:	0014f793          	andi	a5,s1,1
    80001038:	dfd5                	beqz	a5,80000ff4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000103a:	80a9                	srli	s1,s1,0xa
    8000103c:	04b2                	slli	s1,s1,0xc
    8000103e:	b7c5                	j	8000101e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001040:	00c9d513          	srli	a0,s3,0xc
    80001044:	1ff57513          	andi	a0,a0,511
    80001048:	050e                	slli	a0,a0,0x3
    8000104a:	9526                	add	a0,a0,s1
}
    8000104c:	70e2                	ld	ra,56(sp)
    8000104e:	7442                	ld	s0,48(sp)
    80001050:	74a2                	ld	s1,40(sp)
    80001052:	7902                	ld	s2,32(sp)
    80001054:	69e2                	ld	s3,24(sp)
    80001056:	6a42                	ld	s4,16(sp)
    80001058:	6aa2                	ld	s5,8(sp)
    8000105a:	6b02                	ld	s6,0(sp)
    8000105c:	6121                	addi	sp,sp,64
    8000105e:	8082                	ret
        return 0;
    80001060:	4501                	li	a0,0
    80001062:	b7ed                	j	8000104c <walk+0x8e>

0000000080001064 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001064:	57fd                	li	a5,-1
    80001066:	83e9                	srli	a5,a5,0x1a
    80001068:	00b7f463          	bgeu	a5,a1,80001070 <walkaddr+0xc>
    return 0;
    8000106c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000106e:	8082                	ret
{
    80001070:	1141                	addi	sp,sp,-16
    80001072:	e406                	sd	ra,8(sp)
    80001074:	e022                	sd	s0,0(sp)
    80001076:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001078:	4601                	li	a2,0
    8000107a:	00000097          	auipc	ra,0x0
    8000107e:	f44080e7          	jalr	-188(ra) # 80000fbe <walk>
  if(pte == 0)
    80001082:	c105                	beqz	a0,800010a2 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001084:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001086:	0117f693          	andi	a3,a5,17
    8000108a:	4745                	li	a4,17
    return 0;
    8000108c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000108e:	00e68663          	beq	a3,a4,8000109a <walkaddr+0x36>
}
    80001092:	60a2                	ld	ra,8(sp)
    80001094:	6402                	ld	s0,0(sp)
    80001096:	0141                	addi	sp,sp,16
    80001098:	8082                	ret
  pa = PTE2PA(*pte);
    8000109a:	00a7d513          	srli	a0,a5,0xa
    8000109e:	0532                	slli	a0,a0,0xc
  return pa;
    800010a0:	bfcd                	j	80001092 <walkaddr+0x2e>
    return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7fd                	j	80001092 <walkaddr+0x2e>

00000000800010a6 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010a6:	715d                	addi	sp,sp,-80
    800010a8:	e486                	sd	ra,72(sp)
    800010aa:	e0a2                	sd	s0,64(sp)
    800010ac:	fc26                	sd	s1,56(sp)
    800010ae:	f84a                	sd	s2,48(sp)
    800010b0:	f44e                	sd	s3,40(sp)
    800010b2:	f052                	sd	s4,32(sp)
    800010b4:	ec56                	sd	s5,24(sp)
    800010b6:	e85a                	sd	s6,16(sp)
    800010b8:	e45e                	sd	s7,8(sp)
    800010ba:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010bc:	c639                	beqz	a2,8000110a <mappages+0x64>
    800010be:	8aaa                	mv	s5,a0
    800010c0:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010c2:	77fd                	lui	a5,0xfffff
    800010c4:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010c8:	15fd                	addi	a1,a1,-1
    800010ca:	00c589b3          	add	s3,a1,a2
    800010ce:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010d2:	8952                	mv	s2,s4
    800010d4:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d8:	6b85                	lui	s7,0x1
    800010da:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010de:	4605                	li	a2,1
    800010e0:	85ca                	mv	a1,s2
    800010e2:	8556                	mv	a0,s5
    800010e4:	00000097          	auipc	ra,0x0
    800010e8:	eda080e7          	jalr	-294(ra) # 80000fbe <walk>
    800010ec:	cd1d                	beqz	a0,8000112a <mappages+0x84>
    if(*pte & PTE_V)
    800010ee:	611c                	ld	a5,0(a0)
    800010f0:	8b85                	andi	a5,a5,1
    800010f2:	e785                	bnez	a5,8000111a <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010f4:	80b1                	srli	s1,s1,0xc
    800010f6:	04aa                	slli	s1,s1,0xa
    800010f8:	0164e4b3          	or	s1,s1,s6
    800010fc:	0014e493          	ori	s1,s1,1
    80001100:	e104                	sd	s1,0(a0)
    if(a == last)
    80001102:	05390063          	beq	s2,s3,80001142 <mappages+0x9c>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001108:	bfc9                	j	800010da <mappages+0x34>
    panic("mappages: size");
    8000110a:	00007517          	auipc	a0,0x7
    8000110e:	fce50513          	addi	a0,a0,-50 # 800080d8 <digits+0x98>
    80001112:	fffff097          	auipc	ra,0xfffff
    80001116:	42c080e7          	jalr	1068(ra) # 8000053e <panic>
      panic("mappages: remap");
    8000111a:	00007517          	auipc	a0,0x7
    8000111e:	fce50513          	addi	a0,a0,-50 # 800080e8 <digits+0xa8>
    80001122:	fffff097          	auipc	ra,0xfffff
    80001126:	41c080e7          	jalr	1052(ra) # 8000053e <panic>
      return -1;
    8000112a:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000112c:	60a6                	ld	ra,72(sp)
    8000112e:	6406                	ld	s0,64(sp)
    80001130:	74e2                	ld	s1,56(sp)
    80001132:	7942                	ld	s2,48(sp)
    80001134:	79a2                	ld	s3,40(sp)
    80001136:	7a02                	ld	s4,32(sp)
    80001138:	6ae2                	ld	s5,24(sp)
    8000113a:	6b42                	ld	s6,16(sp)
    8000113c:	6ba2                	ld	s7,8(sp)
    8000113e:	6161                	addi	sp,sp,80
    80001140:	8082                	ret
  return 0;
    80001142:	4501                	li	a0,0
    80001144:	b7e5                	j	8000112c <mappages+0x86>

0000000080001146 <kvmmap>:
{
    80001146:	1141                	addi	sp,sp,-16
    80001148:	e406                	sd	ra,8(sp)
    8000114a:	e022                	sd	s0,0(sp)
    8000114c:	0800                	addi	s0,sp,16
    8000114e:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001150:	86b2                	mv	a3,a2
    80001152:	863e                	mv	a2,a5
    80001154:	00000097          	auipc	ra,0x0
    80001158:	f52080e7          	jalr	-174(ra) # 800010a6 <mappages>
    8000115c:	e509                	bnez	a0,80001166 <kvmmap+0x20>
}
    8000115e:	60a2                	ld	ra,8(sp)
    80001160:	6402                	ld	s0,0(sp)
    80001162:	0141                	addi	sp,sp,16
    80001164:	8082                	ret
    panic("kvmmap");
    80001166:	00007517          	auipc	a0,0x7
    8000116a:	f9250513          	addi	a0,a0,-110 # 800080f8 <digits+0xb8>
    8000116e:	fffff097          	auipc	ra,0xfffff
    80001172:	3d0080e7          	jalr	976(ra) # 8000053e <panic>

0000000080001176 <kvmmake>:
{
    80001176:	1101                	addi	sp,sp,-32
    80001178:	ec06                	sd	ra,24(sp)
    8000117a:	e822                	sd	s0,16(sp)
    8000117c:	e426                	sd	s1,8(sp)
    8000117e:	e04a                	sd	s2,0(sp)
    80001180:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001182:	00000097          	auipc	ra,0x0
    80001186:	964080e7          	jalr	-1692(ra) # 80000ae6 <kalloc>
    8000118a:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000118c:	6605                	lui	a2,0x1
    8000118e:	4581                	li	a1,0
    80001190:	00000097          	auipc	ra,0x0
    80001194:	b42080e7          	jalr	-1214(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001198:	4719                	li	a4,6
    8000119a:	6685                	lui	a3,0x1
    8000119c:	10000637          	lui	a2,0x10000
    800011a0:	100005b7          	lui	a1,0x10000
    800011a4:	8526                	mv	a0,s1
    800011a6:	00000097          	auipc	ra,0x0
    800011aa:	fa0080e7          	jalr	-96(ra) # 80001146 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011ae:	4719                	li	a4,6
    800011b0:	6685                	lui	a3,0x1
    800011b2:	10001637          	lui	a2,0x10001
    800011b6:	100015b7          	lui	a1,0x10001
    800011ba:	8526                	mv	a0,s1
    800011bc:	00000097          	auipc	ra,0x0
    800011c0:	f8a080e7          	jalr	-118(ra) # 80001146 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011c4:	4719                	li	a4,6
    800011c6:	004006b7          	lui	a3,0x400
    800011ca:	0c000637          	lui	a2,0xc000
    800011ce:	0c0005b7          	lui	a1,0xc000
    800011d2:	8526                	mv	a0,s1
    800011d4:	00000097          	auipc	ra,0x0
    800011d8:	f72080e7          	jalr	-142(ra) # 80001146 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011dc:	00007917          	auipc	s2,0x7
    800011e0:	e2490913          	addi	s2,s2,-476 # 80008000 <etext>
    800011e4:	4729                	li	a4,10
    800011e6:	80007697          	auipc	a3,0x80007
    800011ea:	e1a68693          	addi	a3,a3,-486 # 8000 <_entry-0x7fff8000>
    800011ee:	4605                	li	a2,1
    800011f0:	067e                	slli	a2,a2,0x1f
    800011f2:	85b2                	mv	a1,a2
    800011f4:	8526                	mv	a0,s1
    800011f6:	00000097          	auipc	ra,0x0
    800011fa:	f50080e7          	jalr	-176(ra) # 80001146 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011fe:	4719                	li	a4,6
    80001200:	46c5                	li	a3,17
    80001202:	06ee                	slli	a3,a3,0x1b
    80001204:	412686b3          	sub	a3,a3,s2
    80001208:	864a                	mv	a2,s2
    8000120a:	85ca                	mv	a1,s2
    8000120c:	8526                	mv	a0,s1
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	f38080e7          	jalr	-200(ra) # 80001146 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001216:	4729                	li	a4,10
    80001218:	6685                	lui	a3,0x1
    8000121a:	00006617          	auipc	a2,0x6
    8000121e:	de660613          	addi	a2,a2,-538 # 80007000 <_trampoline>
    80001222:	040005b7          	lui	a1,0x4000
    80001226:	15fd                	addi	a1,a1,-1
    80001228:	05b2                	slli	a1,a1,0xc
    8000122a:	8526                	mv	a0,s1
    8000122c:	00000097          	auipc	ra,0x0
    80001230:	f1a080e7          	jalr	-230(ra) # 80001146 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	608080e7          	jalr	1544(ra) # 8000183e <proc_mapstacks>
}
    8000123e:	8526                	mv	a0,s1
    80001240:	60e2                	ld	ra,24(sp)
    80001242:	6442                	ld	s0,16(sp)
    80001244:	64a2                	ld	s1,8(sp)
    80001246:	6902                	ld	s2,0(sp)
    80001248:	6105                	addi	sp,sp,32
    8000124a:	8082                	ret

000000008000124c <kvminit>:
{
    8000124c:	1141                	addi	sp,sp,-16
    8000124e:	e406                	sd	ra,8(sp)
    80001250:	e022                	sd	s0,0(sp)
    80001252:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001254:	00000097          	auipc	ra,0x0
    80001258:	f22080e7          	jalr	-222(ra) # 80001176 <kvmmake>
    8000125c:	00007797          	auipc	a5,0x7
    80001260:	6aa7b223          	sd	a0,1700(a5) # 80008900 <kernel_pagetable>
}
    80001264:	60a2                	ld	ra,8(sp)
    80001266:	6402                	ld	s0,0(sp)
    80001268:	0141                	addi	sp,sp,16
    8000126a:	8082                	ret

000000008000126c <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000126c:	715d                	addi	sp,sp,-80
    8000126e:	e486                	sd	ra,72(sp)
    80001270:	e0a2                	sd	s0,64(sp)
    80001272:	fc26                	sd	s1,56(sp)
    80001274:	f84a                	sd	s2,48(sp)
    80001276:	f44e                	sd	s3,40(sp)
    80001278:	f052                	sd	s4,32(sp)
    8000127a:	ec56                	sd	s5,24(sp)
    8000127c:	e85a                	sd	s6,16(sp)
    8000127e:	e45e                	sd	s7,8(sp)
    80001280:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001282:	03459793          	slli	a5,a1,0x34
    80001286:	e795                	bnez	a5,800012b2 <uvmunmap+0x46>
    80001288:	8a2a                	mv	s4,a0
    8000128a:	892e                	mv	s2,a1
    8000128c:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	0632                	slli	a2,a2,0xc
    80001290:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001294:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001296:	6b05                	lui	s6,0x1
    80001298:	0735e263          	bltu	a1,s3,800012fc <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000129c:	60a6                	ld	ra,72(sp)
    8000129e:	6406                	ld	s0,64(sp)
    800012a0:	74e2                	ld	s1,56(sp)
    800012a2:	7942                	ld	s2,48(sp)
    800012a4:	79a2                	ld	s3,40(sp)
    800012a6:	7a02                	ld	s4,32(sp)
    800012a8:	6ae2                	ld	s5,24(sp)
    800012aa:	6b42                	ld	s6,16(sp)
    800012ac:	6ba2                	ld	s7,8(sp)
    800012ae:	6161                	addi	sp,sp,80
    800012b0:	8082                	ret
    panic("uvmunmap: not aligned");
    800012b2:	00007517          	auipc	a0,0x7
    800012b6:	e4e50513          	addi	a0,a0,-434 # 80008100 <digits+0xc0>
    800012ba:	fffff097          	auipc	ra,0xfffff
    800012be:	284080e7          	jalr	644(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012c2:	00007517          	auipc	a0,0x7
    800012c6:	e5650513          	addi	a0,a0,-426 # 80008118 <digits+0xd8>
    800012ca:	fffff097          	auipc	ra,0xfffff
    800012ce:	274080e7          	jalr	628(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012d2:	00007517          	auipc	a0,0x7
    800012d6:	e5650513          	addi	a0,a0,-426 # 80008128 <digits+0xe8>
    800012da:	fffff097          	auipc	ra,0xfffff
    800012de:	264080e7          	jalr	612(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012e2:	00007517          	auipc	a0,0x7
    800012e6:	e5e50513          	addi	a0,a0,-418 # 80008140 <digits+0x100>
    800012ea:	fffff097          	auipc	ra,0xfffff
    800012ee:	254080e7          	jalr	596(ra) # 8000053e <panic>
    *pte = 0;
    800012f2:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012f6:	995a                	add	s2,s2,s6
    800012f8:	fb3972e3          	bgeu	s2,s3,8000129c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012fc:	4601                	li	a2,0
    800012fe:	85ca                	mv	a1,s2
    80001300:	8552                	mv	a0,s4
    80001302:	00000097          	auipc	ra,0x0
    80001306:	cbc080e7          	jalr	-836(ra) # 80000fbe <walk>
    8000130a:	84aa                	mv	s1,a0
    8000130c:	d95d                	beqz	a0,800012c2 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000130e:	6108                	ld	a0,0(a0)
    80001310:	00157793          	andi	a5,a0,1
    80001314:	dfdd                	beqz	a5,800012d2 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001316:	3ff57793          	andi	a5,a0,1023
    8000131a:	fd7784e3          	beq	a5,s7,800012e2 <uvmunmap+0x76>
    if(do_free){
    8000131e:	fc0a8ae3          	beqz	s5,800012f2 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001322:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001324:	0532                	slli	a0,a0,0xc
    80001326:	fffff097          	auipc	ra,0xfffff
    8000132a:	6c4080e7          	jalr	1732(ra) # 800009ea <kfree>
    8000132e:	b7d1                	j	800012f2 <uvmunmap+0x86>

0000000080001330 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001330:	1101                	addi	sp,sp,-32
    80001332:	ec06                	sd	ra,24(sp)
    80001334:	e822                	sd	s0,16(sp)
    80001336:	e426                	sd	s1,8(sp)
    80001338:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000133a:	fffff097          	auipc	ra,0xfffff
    8000133e:	7ac080e7          	jalr	1964(ra) # 80000ae6 <kalloc>
    80001342:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001344:	c519                	beqz	a0,80001352 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001346:	6605                	lui	a2,0x1
    80001348:	4581                	li	a1,0
    8000134a:	00000097          	auipc	ra,0x0
    8000134e:	988080e7          	jalr	-1656(ra) # 80000cd2 <memset>
  return pagetable;
}
    80001352:	8526                	mv	a0,s1
    80001354:	60e2                	ld	ra,24(sp)
    80001356:	6442                	ld	s0,16(sp)
    80001358:	64a2                	ld	s1,8(sp)
    8000135a:	6105                	addi	sp,sp,32
    8000135c:	8082                	ret

000000008000135e <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000135e:	7179                	addi	sp,sp,-48
    80001360:	f406                	sd	ra,40(sp)
    80001362:	f022                	sd	s0,32(sp)
    80001364:	ec26                	sd	s1,24(sp)
    80001366:	e84a                	sd	s2,16(sp)
    80001368:	e44e                	sd	s3,8(sp)
    8000136a:	e052                	sd	s4,0(sp)
    8000136c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000136e:	6785                	lui	a5,0x1
    80001370:	04f67863          	bgeu	a2,a5,800013c0 <uvmfirst+0x62>
    80001374:	8a2a                	mv	s4,a0
    80001376:	89ae                	mv	s3,a1
    80001378:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000137a:	fffff097          	auipc	ra,0xfffff
    8000137e:	76c080e7          	jalr	1900(ra) # 80000ae6 <kalloc>
    80001382:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001384:	6605                	lui	a2,0x1
    80001386:	4581                	li	a1,0
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	94a080e7          	jalr	-1718(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001390:	4779                	li	a4,30
    80001392:	86ca                	mv	a3,s2
    80001394:	6605                	lui	a2,0x1
    80001396:	4581                	li	a1,0
    80001398:	8552                	mv	a0,s4
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	d0c080e7          	jalr	-756(ra) # 800010a6 <mappages>
  memmove(mem, src, sz);
    800013a2:	8626                	mv	a2,s1
    800013a4:	85ce                	mv	a1,s3
    800013a6:	854a                	mv	a0,s2
    800013a8:	00000097          	auipc	ra,0x0
    800013ac:	986080e7          	jalr	-1658(ra) # 80000d2e <memmove>
}
    800013b0:	70a2                	ld	ra,40(sp)
    800013b2:	7402                	ld	s0,32(sp)
    800013b4:	64e2                	ld	s1,24(sp)
    800013b6:	6942                	ld	s2,16(sp)
    800013b8:	69a2                	ld	s3,8(sp)
    800013ba:	6a02                	ld	s4,0(sp)
    800013bc:	6145                	addi	sp,sp,48
    800013be:	8082                	ret
    panic("uvmfirst: more than a page");
    800013c0:	00007517          	auipc	a0,0x7
    800013c4:	d9850513          	addi	a0,a0,-616 # 80008158 <digits+0x118>
    800013c8:	fffff097          	auipc	ra,0xfffff
    800013cc:	176080e7          	jalr	374(ra) # 8000053e <panic>

00000000800013d0 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013d0:	1101                	addi	sp,sp,-32
    800013d2:	ec06                	sd	ra,24(sp)
    800013d4:	e822                	sd	s0,16(sp)
    800013d6:	e426                	sd	s1,8(sp)
    800013d8:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013da:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013dc:	00b67d63          	bgeu	a2,a1,800013f6 <uvmdealloc+0x26>
    800013e0:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013e2:	6785                	lui	a5,0x1
    800013e4:	17fd                	addi	a5,a5,-1
    800013e6:	00f60733          	add	a4,a2,a5
    800013ea:	767d                	lui	a2,0xfffff
    800013ec:	8f71                	and	a4,a4,a2
    800013ee:	97ae                	add	a5,a5,a1
    800013f0:	8ff1                	and	a5,a5,a2
    800013f2:	00f76863          	bltu	a4,a5,80001402 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013f6:	8526                	mv	a0,s1
    800013f8:	60e2                	ld	ra,24(sp)
    800013fa:	6442                	ld	s0,16(sp)
    800013fc:	64a2                	ld	s1,8(sp)
    800013fe:	6105                	addi	sp,sp,32
    80001400:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001402:	8f99                	sub	a5,a5,a4
    80001404:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001406:	4685                	li	a3,1
    80001408:	0007861b          	sext.w	a2,a5
    8000140c:	85ba                	mv	a1,a4
    8000140e:	00000097          	auipc	ra,0x0
    80001412:	e5e080e7          	jalr	-418(ra) # 8000126c <uvmunmap>
    80001416:	b7c5                	j	800013f6 <uvmdealloc+0x26>

0000000080001418 <uvmalloc>:
  if(newsz < oldsz)
    80001418:	0ab66563          	bltu	a2,a1,800014c2 <uvmalloc+0xaa>
{
    8000141c:	7139                	addi	sp,sp,-64
    8000141e:	fc06                	sd	ra,56(sp)
    80001420:	f822                	sd	s0,48(sp)
    80001422:	f426                	sd	s1,40(sp)
    80001424:	f04a                	sd	s2,32(sp)
    80001426:	ec4e                	sd	s3,24(sp)
    80001428:	e852                	sd	s4,16(sp)
    8000142a:	e456                	sd	s5,8(sp)
    8000142c:	e05a                	sd	s6,0(sp)
    8000142e:	0080                	addi	s0,sp,64
    80001430:	8aaa                	mv	s5,a0
    80001432:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001434:	6985                	lui	s3,0x1
    80001436:	19fd                	addi	s3,s3,-1
    80001438:	95ce                	add	a1,a1,s3
    8000143a:	79fd                	lui	s3,0xfffff
    8000143c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001440:	08c9f363          	bgeu	s3,a2,800014c6 <uvmalloc+0xae>
    80001444:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001446:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000144a:	fffff097          	auipc	ra,0xfffff
    8000144e:	69c080e7          	jalr	1692(ra) # 80000ae6 <kalloc>
    80001452:	84aa                	mv	s1,a0
    if(mem == 0){
    80001454:	c51d                	beqz	a0,80001482 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001456:	6605                	lui	a2,0x1
    80001458:	4581                	li	a1,0
    8000145a:	00000097          	auipc	ra,0x0
    8000145e:	878080e7          	jalr	-1928(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001462:	875a                	mv	a4,s6
    80001464:	86a6                	mv	a3,s1
    80001466:	6605                	lui	a2,0x1
    80001468:	85ca                	mv	a1,s2
    8000146a:	8556                	mv	a0,s5
    8000146c:	00000097          	auipc	ra,0x0
    80001470:	c3a080e7          	jalr	-966(ra) # 800010a6 <mappages>
    80001474:	e90d                	bnez	a0,800014a6 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001476:	6785                	lui	a5,0x1
    80001478:	993e                	add	s2,s2,a5
    8000147a:	fd4968e3          	bltu	s2,s4,8000144a <uvmalloc+0x32>
  return newsz;
    8000147e:	8552                	mv	a0,s4
    80001480:	a809                	j	80001492 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001482:	864e                	mv	a2,s3
    80001484:	85ca                	mv	a1,s2
    80001486:	8556                	mv	a0,s5
    80001488:	00000097          	auipc	ra,0x0
    8000148c:	f48080e7          	jalr	-184(ra) # 800013d0 <uvmdealloc>
      return 0;
    80001490:	4501                	li	a0,0
}
    80001492:	70e2                	ld	ra,56(sp)
    80001494:	7442                	ld	s0,48(sp)
    80001496:	74a2                	ld	s1,40(sp)
    80001498:	7902                	ld	s2,32(sp)
    8000149a:	69e2                	ld	s3,24(sp)
    8000149c:	6a42                	ld	s4,16(sp)
    8000149e:	6aa2                	ld	s5,8(sp)
    800014a0:	6b02                	ld	s6,0(sp)
    800014a2:	6121                	addi	sp,sp,64
    800014a4:	8082                	ret
      kfree(mem);
    800014a6:	8526                	mv	a0,s1
    800014a8:	fffff097          	auipc	ra,0xfffff
    800014ac:	542080e7          	jalr	1346(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b0:	864e                	mv	a2,s3
    800014b2:	85ca                	mv	a1,s2
    800014b4:	8556                	mv	a0,s5
    800014b6:	00000097          	auipc	ra,0x0
    800014ba:	f1a080e7          	jalr	-230(ra) # 800013d0 <uvmdealloc>
      return 0;
    800014be:	4501                	li	a0,0
    800014c0:	bfc9                	j	80001492 <uvmalloc+0x7a>
    return oldsz;
    800014c2:	852e                	mv	a0,a1
}
    800014c4:	8082                	ret
  return newsz;
    800014c6:	8532                	mv	a0,a2
    800014c8:	b7e9                	j	80001492 <uvmalloc+0x7a>

00000000800014ca <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014ca:	7179                	addi	sp,sp,-48
    800014cc:	f406                	sd	ra,40(sp)
    800014ce:	f022                	sd	s0,32(sp)
    800014d0:	ec26                	sd	s1,24(sp)
    800014d2:	e84a                	sd	s2,16(sp)
    800014d4:	e44e                	sd	s3,8(sp)
    800014d6:	e052                	sd	s4,0(sp)
    800014d8:	1800                	addi	s0,sp,48
    800014da:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014dc:	84aa                	mv	s1,a0
    800014de:	6905                	lui	s2,0x1
    800014e0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e2:	4985                	li	s3,1
    800014e4:	a821                	j	800014fc <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e6:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014e8:	0532                	slli	a0,a0,0xc
    800014ea:	00000097          	auipc	ra,0x0
    800014ee:	fe0080e7          	jalr	-32(ra) # 800014ca <freewalk>
      pagetable[i] = 0;
    800014f2:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f6:	04a1                	addi	s1,s1,8
    800014f8:	03248163          	beq	s1,s2,8000151a <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fc:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014fe:	00f57793          	andi	a5,a0,15
    80001502:	ff3782e3          	beq	a5,s3,800014e6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001506:	8905                	andi	a0,a0,1
    80001508:	d57d                	beqz	a0,800014f6 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150a:	00007517          	auipc	a0,0x7
    8000150e:	c6e50513          	addi	a0,a0,-914 # 80008178 <digits+0x138>
    80001512:	fffff097          	auipc	ra,0xfffff
    80001516:	02c080e7          	jalr	44(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151a:	8552                	mv	a0,s4
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	4ce080e7          	jalr	1230(ra) # 800009ea <kfree>
}
    80001524:	70a2                	ld	ra,40(sp)
    80001526:	7402                	ld	s0,32(sp)
    80001528:	64e2                	ld	s1,24(sp)
    8000152a:	6942                	ld	s2,16(sp)
    8000152c:	69a2                	ld	s3,8(sp)
    8000152e:	6a02                	ld	s4,0(sp)
    80001530:	6145                	addi	sp,sp,48
    80001532:	8082                	ret

0000000080001534 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001534:	1101                	addi	sp,sp,-32
    80001536:	ec06                	sd	ra,24(sp)
    80001538:	e822                	sd	s0,16(sp)
    8000153a:	e426                	sd	s1,8(sp)
    8000153c:	1000                	addi	s0,sp,32
    8000153e:	84aa                	mv	s1,a0
  if(sz > 0)
    80001540:	e999                	bnez	a1,80001556 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001542:	8526                	mv	a0,s1
    80001544:	00000097          	auipc	ra,0x0
    80001548:	f86080e7          	jalr	-122(ra) # 800014ca <freewalk>
}
    8000154c:	60e2                	ld	ra,24(sp)
    8000154e:	6442                	ld	s0,16(sp)
    80001550:	64a2                	ld	s1,8(sp)
    80001552:	6105                	addi	sp,sp,32
    80001554:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001556:	6605                	lui	a2,0x1
    80001558:	167d                	addi	a2,a2,-1
    8000155a:	962e                	add	a2,a2,a1
    8000155c:	4685                	li	a3,1
    8000155e:	8231                	srli	a2,a2,0xc
    80001560:	4581                	li	a1,0
    80001562:	00000097          	auipc	ra,0x0
    80001566:	d0a080e7          	jalr	-758(ra) # 8000126c <uvmunmap>
    8000156a:	bfe1                	j	80001542 <uvmfree+0xe>

000000008000156c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156c:	c679                	beqz	a2,8000163a <uvmcopy+0xce>
{
    8000156e:	715d                	addi	sp,sp,-80
    80001570:	e486                	sd	ra,72(sp)
    80001572:	e0a2                	sd	s0,64(sp)
    80001574:	fc26                	sd	s1,56(sp)
    80001576:	f84a                	sd	s2,48(sp)
    80001578:	f44e                	sd	s3,40(sp)
    8000157a:	f052                	sd	s4,32(sp)
    8000157c:	ec56                	sd	s5,24(sp)
    8000157e:	e85a                	sd	s6,16(sp)
    80001580:	e45e                	sd	s7,8(sp)
    80001582:	0880                	addi	s0,sp,80
    80001584:	8b2a                	mv	s6,a0
    80001586:	8aae                	mv	s5,a1
    80001588:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158a:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158c:	4601                	li	a2,0
    8000158e:	85ce                	mv	a1,s3
    80001590:	855a                	mv	a0,s6
    80001592:	00000097          	auipc	ra,0x0
    80001596:	a2c080e7          	jalr	-1492(ra) # 80000fbe <walk>
    8000159a:	c531                	beqz	a0,800015e6 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159c:	6118                	ld	a4,0(a0)
    8000159e:	00177793          	andi	a5,a4,1
    800015a2:	cbb1                	beqz	a5,800015f6 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a4:	00a75593          	srli	a1,a4,0xa
    800015a8:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ac:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b0:	fffff097          	auipc	ra,0xfffff
    800015b4:	536080e7          	jalr	1334(ra) # 80000ae6 <kalloc>
    800015b8:	892a                	mv	s2,a0
    800015ba:	c939                	beqz	a0,80001610 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015bc:	6605                	lui	a2,0x1
    800015be:	85de                	mv	a1,s7
    800015c0:	fffff097          	auipc	ra,0xfffff
    800015c4:	76e080e7          	jalr	1902(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c8:	8726                	mv	a4,s1
    800015ca:	86ca                	mv	a3,s2
    800015cc:	6605                	lui	a2,0x1
    800015ce:	85ce                	mv	a1,s3
    800015d0:	8556                	mv	a0,s5
    800015d2:	00000097          	auipc	ra,0x0
    800015d6:	ad4080e7          	jalr	-1324(ra) # 800010a6 <mappages>
    800015da:	e515                	bnez	a0,80001606 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015dc:	6785                	lui	a5,0x1
    800015de:	99be                	add	s3,s3,a5
    800015e0:	fb49e6e3          	bltu	s3,s4,8000158c <uvmcopy+0x20>
    800015e4:	a081                	j	80001624 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e6:	00007517          	auipc	a0,0x7
    800015ea:	ba250513          	addi	a0,a0,-1118 # 80008188 <digits+0x148>
    800015ee:	fffff097          	auipc	ra,0xfffff
    800015f2:	f50080e7          	jalr	-176(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f6:	00007517          	auipc	a0,0x7
    800015fa:	bb250513          	addi	a0,a0,-1102 # 800081a8 <digits+0x168>
    800015fe:	fffff097          	auipc	ra,0xfffff
    80001602:	f40080e7          	jalr	-192(ra) # 8000053e <panic>
      kfree(mem);
    80001606:	854a                	mv	a0,s2
    80001608:	fffff097          	auipc	ra,0xfffff
    8000160c:	3e2080e7          	jalr	994(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001610:	4685                	li	a3,1
    80001612:	00c9d613          	srli	a2,s3,0xc
    80001616:	4581                	li	a1,0
    80001618:	8556                	mv	a0,s5
    8000161a:	00000097          	auipc	ra,0x0
    8000161e:	c52080e7          	jalr	-942(ra) # 8000126c <uvmunmap>
  return -1;
    80001622:	557d                	li	a0,-1
}
    80001624:	60a6                	ld	ra,72(sp)
    80001626:	6406                	ld	s0,64(sp)
    80001628:	74e2                	ld	s1,56(sp)
    8000162a:	7942                	ld	s2,48(sp)
    8000162c:	79a2                	ld	s3,40(sp)
    8000162e:	7a02                	ld	s4,32(sp)
    80001630:	6ae2                	ld	s5,24(sp)
    80001632:	6b42                	ld	s6,16(sp)
    80001634:	6ba2                	ld	s7,8(sp)
    80001636:	6161                	addi	sp,sp,80
    80001638:	8082                	ret
  return 0;
    8000163a:	4501                	li	a0,0
}
    8000163c:	8082                	ret

000000008000163e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163e:	1141                	addi	sp,sp,-16
    80001640:	e406                	sd	ra,8(sp)
    80001642:	e022                	sd	s0,0(sp)
    80001644:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001646:	4601                	li	a2,0
    80001648:	00000097          	auipc	ra,0x0
    8000164c:	976080e7          	jalr	-1674(ra) # 80000fbe <walk>
  if(pte == 0)
    80001650:	c901                	beqz	a0,80001660 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001652:	611c                	ld	a5,0(a0)
    80001654:	9bbd                	andi	a5,a5,-17
    80001656:	e11c                	sd	a5,0(a0)
}
    80001658:	60a2                	ld	ra,8(sp)
    8000165a:	6402                	ld	s0,0(sp)
    8000165c:	0141                	addi	sp,sp,16
    8000165e:	8082                	ret
    panic("uvmclear");
    80001660:	00007517          	auipc	a0,0x7
    80001664:	b6850513          	addi	a0,a0,-1176 # 800081c8 <digits+0x188>
    80001668:	fffff097          	auipc	ra,0xfffff
    8000166c:	ed6080e7          	jalr	-298(ra) # 8000053e <panic>

0000000080001670 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001670:	c6bd                	beqz	a3,800016de <copyout+0x6e>
{
    80001672:	715d                	addi	sp,sp,-80
    80001674:	e486                	sd	ra,72(sp)
    80001676:	e0a2                	sd	s0,64(sp)
    80001678:	fc26                	sd	s1,56(sp)
    8000167a:	f84a                	sd	s2,48(sp)
    8000167c:	f44e                	sd	s3,40(sp)
    8000167e:	f052                	sd	s4,32(sp)
    80001680:	ec56                	sd	s5,24(sp)
    80001682:	e85a                	sd	s6,16(sp)
    80001684:	e45e                	sd	s7,8(sp)
    80001686:	e062                	sd	s8,0(sp)
    80001688:	0880                	addi	s0,sp,80
    8000168a:	8b2a                	mv	s6,a0
    8000168c:	8c2e                	mv	s8,a1
    8000168e:	8a32                	mv	s4,a2
    80001690:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001692:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001694:	6a85                	lui	s5,0x1
    80001696:	a015                	j	800016ba <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001698:	9562                	add	a0,a0,s8
    8000169a:	0004861b          	sext.w	a2,s1
    8000169e:	85d2                	mv	a1,s4
    800016a0:	41250533          	sub	a0,a0,s2
    800016a4:	fffff097          	auipc	ra,0xfffff
    800016a8:	68a080e7          	jalr	1674(ra) # 80000d2e <memmove>

    len -= n;
    800016ac:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b0:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b2:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b6:	02098263          	beqz	s3,800016da <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ba:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016be:	85ca                	mv	a1,s2
    800016c0:	855a                	mv	a0,s6
    800016c2:	00000097          	auipc	ra,0x0
    800016c6:	9a2080e7          	jalr	-1630(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    800016ca:	cd01                	beqz	a0,800016e2 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016cc:	418904b3          	sub	s1,s2,s8
    800016d0:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d2:	fc99f3e3          	bgeu	s3,s1,80001698 <copyout+0x28>
    800016d6:	84ce                	mv	s1,s3
    800016d8:	b7c1                	j	80001698 <copyout+0x28>
  }
  return 0;
    800016da:	4501                	li	a0,0
    800016dc:	a021                	j	800016e4 <copyout+0x74>
    800016de:	4501                	li	a0,0
}
    800016e0:	8082                	ret
      return -1;
    800016e2:	557d                	li	a0,-1
}
    800016e4:	60a6                	ld	ra,72(sp)
    800016e6:	6406                	ld	s0,64(sp)
    800016e8:	74e2                	ld	s1,56(sp)
    800016ea:	7942                	ld	s2,48(sp)
    800016ec:	79a2                	ld	s3,40(sp)
    800016ee:	7a02                	ld	s4,32(sp)
    800016f0:	6ae2                	ld	s5,24(sp)
    800016f2:	6b42                	ld	s6,16(sp)
    800016f4:	6ba2                	ld	s7,8(sp)
    800016f6:	6c02                	ld	s8,0(sp)
    800016f8:	6161                	addi	sp,sp,80
    800016fa:	8082                	ret

00000000800016fc <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fc:	caa5                	beqz	a3,8000176c <copyin+0x70>
{
    800016fe:	715d                	addi	sp,sp,-80
    80001700:	e486                	sd	ra,72(sp)
    80001702:	e0a2                	sd	s0,64(sp)
    80001704:	fc26                	sd	s1,56(sp)
    80001706:	f84a                	sd	s2,48(sp)
    80001708:	f44e                	sd	s3,40(sp)
    8000170a:	f052                	sd	s4,32(sp)
    8000170c:	ec56                	sd	s5,24(sp)
    8000170e:	e85a                	sd	s6,16(sp)
    80001710:	e45e                	sd	s7,8(sp)
    80001712:	e062                	sd	s8,0(sp)
    80001714:	0880                	addi	s0,sp,80
    80001716:	8b2a                	mv	s6,a0
    80001718:	8a2e                	mv	s4,a1
    8000171a:	8c32                	mv	s8,a2
    8000171c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001720:	6a85                	lui	s5,0x1
    80001722:	a01d                	j	80001748 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001724:	018505b3          	add	a1,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412585b3          	sub	a1,a1,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	5fc080e7          	jalr	1532(ra) # 80000d2e <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	914080e7          	jalr	-1772(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f2e3          	bgeu	s3,s1,80001724 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	bf7d                	j	80001724 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x76>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	882080e7          	jalr	-1918(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001854:	0000f497          	auipc	s1,0xf
    80001858:	75c48493          	addi	s1,s1,1884 # 80010fb0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	342a0a13          	addi	s4,s4,834 # 80017bb0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	270080e7          	jalr	624(ra) # 80000ae6 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if (pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	8591                	srai	a1,a1,0x4
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8a6080e7          	jalr	-1882(ra) # 80001146 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a8:	1b048493          	addi	s1,s1,432
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	0000f517          	auipc	a0,0xf
    800018f4:	29050513          	addi	a0,a0,656 # 80010b80 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	24e080e7          	jalr	590(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	0000f517          	auipc	a0,0xf
    8000190c:	29050513          	addi	a0,a0,656 # 80010b98 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	236080e7          	jalr	566(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001918:	0000f497          	auipc	s1,0xf
    8000191c:	69848493          	addi	s1,s1,1688 # 80010fb0 <proc>
  {
    initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000193a:	00016997          	auipc	s3,0x16
    8000193e:	27698993          	addi	s3,s3,630 # 80017bb0 <tickslock>
    initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	200080e7          	jalr	512(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    8000194e:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001952:	415487b3          	sub	a5,s1,s5
    80001956:	8791                	srai	a5,a5,0x4
    80001958:	000a3703          	ld	a4,0(s4)
    8000195c:	02e787b3          	mul	a5,a5,a4
    80001960:	2785                	addiw	a5,a5,1
    80001962:	00d7979b          	slliw	a5,a5,0xd
    80001966:	40f907b3          	sub	a5,s2,a5
    8000196a:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    8000196c:	1b048493          	addi	s1,s1,432
    80001970:	fd3499e3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
}
    80001974:	70e2                	ld	ra,56(sp)
    80001976:	7442                	ld	s0,48(sp)
    80001978:	74a2                	ld	s1,40(sp)
    8000197a:	7902                	ld	s2,32(sp)
    8000197c:	69e2                	ld	s3,24(sp)
    8000197e:	6a42                	ld	s4,16(sp)
    80001980:	6aa2                	ld	s5,8(sp)
    80001982:	6b02                	ld	s6,0(sp)
    80001984:	6121                	addi	sp,sp,64
    80001986:	8082                	ret

0000000080001988 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001988:	1141                	addi	sp,sp,-16
    8000198a:	e422                	sd	s0,8(sp)
    8000198c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001990:	2501                	sext.w	a0,a0
    80001992:	6422                	ld	s0,8(sp)
    80001994:	0141                	addi	sp,sp,16
    80001996:	8082                	ret

0000000080001998 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001998:	1141                	addi	sp,sp,-16
    8000199a:	e422                	sd	s0,8(sp)
    8000199c:	0800                	addi	s0,sp,16
    8000199e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019a0:	2781                	sext.w	a5,a5
    800019a2:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a4:	0000f517          	auipc	a0,0xf
    800019a8:	20c50513          	addi	a0,a0,524 # 80010bb0 <cpus>
    800019ac:	953e                	add	a0,a0,a5
    800019ae:	6422                	ld	s0,8(sp)
    800019b0:	0141                	addi	sp,sp,16
    800019b2:	8082                	ret

00000000800019b4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019b4:	1101                	addi	sp,sp,-32
    800019b6:	ec06                	sd	ra,24(sp)
    800019b8:	e822                	sd	s0,16(sp)
    800019ba:	e426                	sd	s1,8(sp)
    800019bc:	1000                	addi	s0,sp,32
  push_off();
    800019be:	fffff097          	auipc	ra,0xfffff
    800019c2:	1cc080e7          	jalr	460(ra) # 80000b8a <push_off>
    800019c6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c8:	2781                	sext.w	a5,a5
    800019ca:	079e                	slli	a5,a5,0x7
    800019cc:	0000f717          	auipc	a4,0xf
    800019d0:	1b470713          	addi	a4,a4,436 # 80010b80 <pid_lock>
    800019d4:	97ba                	add	a5,a5,a4
    800019d6:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d8:	fffff097          	auipc	ra,0xfffff
    800019dc:	252080e7          	jalr	594(ra) # 80000c2a <pop_off>
  return p;
}
    800019e0:	8526                	mv	a0,s1
    800019e2:	60e2                	ld	ra,24(sp)
    800019e4:	6442                	ld	s0,16(sp)
    800019e6:	64a2                	ld	s1,8(sp)
    800019e8:	6105                	addi	sp,sp,32
    800019ea:	8082                	ret

00000000800019ec <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019ec:	1141                	addi	sp,sp,-16
    800019ee:	e406                	sd	ra,8(sp)
    800019f0:	e022                	sd	s0,0(sp)
    800019f2:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f4:	00000097          	auipc	ra,0x0
    800019f8:	fc0080e7          	jalr	-64(ra) # 800019b4 <myproc>
    800019fc:	fffff097          	auipc	ra,0xfffff
    80001a00:	28e080e7          	jalr	654(ra) # 80000c8a <release>

  if (first)
    80001a04:	00007797          	auipc	a5,0x7
    80001a08:	e6c7a783          	lw	a5,-404(a5) # 80008870 <first.1>
    80001a0c:	eb89                	bnez	a5,80001a1e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0e:	00001097          	auipc	ra,0x1
    80001a12:	1c4080e7          	jalr	452(ra) # 80002bd2 <usertrapret>
}
    80001a16:	60a2                	ld	ra,8(sp)
    80001a18:	6402                	ld	s0,0(sp)
    80001a1a:	0141                	addi	sp,sp,16
    80001a1c:	8082                	ret
    first = 0;
    80001a1e:	00007797          	auipc	a5,0x7
    80001a22:	e407a923          	sw	zero,-430(a5) # 80008870 <first.1>
    fsinit(ROOTDEV);
    80001a26:	4505                	li	a0,1
    80001a28:	00002097          	auipc	ra,0x2
    80001a2c:	072080e7          	jalr	114(ra) # 80003a9a <fsinit>
    80001a30:	bff9                	j	80001a0e <forkret+0x22>

0000000080001a32 <allocpid>:
{
    80001a32:	1101                	addi	sp,sp,-32
    80001a34:	ec06                	sd	ra,24(sp)
    80001a36:	e822                	sd	s0,16(sp)
    80001a38:	e426                	sd	s1,8(sp)
    80001a3a:	e04a                	sd	s2,0(sp)
    80001a3c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3e:	0000f917          	auipc	s2,0xf
    80001a42:	14290913          	addi	s2,s2,322 # 80010b80 <pid_lock>
    80001a46:	854a                	mv	a0,s2
    80001a48:	fffff097          	auipc	ra,0xfffff
    80001a4c:	18e080e7          	jalr	398(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a50:	00007797          	auipc	a5,0x7
    80001a54:	e2478793          	addi	a5,a5,-476 # 80008874 <nextpid>
    80001a58:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a5a:	0014871b          	addiw	a4,s1,1
    80001a5e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a60:	854a                	mv	a0,s2
    80001a62:	fffff097          	auipc	ra,0xfffff
    80001a66:	228080e7          	jalr	552(ra) # 80000c8a <release>
}
    80001a6a:	8526                	mv	a0,s1
    80001a6c:	60e2                	ld	ra,24(sp)
    80001a6e:	6442                	ld	s0,16(sp)
    80001a70:	64a2                	ld	s1,8(sp)
    80001a72:	6902                	ld	s2,0(sp)
    80001a74:	6105                	addi	sp,sp,32
    80001a76:	8082                	ret

0000000080001a78 <proc_pagetable>:
{
    80001a78:	1101                	addi	sp,sp,-32
    80001a7a:	ec06                	sd	ra,24(sp)
    80001a7c:	e822                	sd	s0,16(sp)
    80001a7e:	e426                	sd	s1,8(sp)
    80001a80:	e04a                	sd	s2,0(sp)
    80001a82:	1000                	addi	s0,sp,32
    80001a84:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a86:	00000097          	auipc	ra,0x0
    80001a8a:	8aa080e7          	jalr	-1878(ra) # 80001330 <uvmcreate>
    80001a8e:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a90:	c121                	beqz	a0,80001ad0 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a92:	4729                	li	a4,10
    80001a94:	00005697          	auipc	a3,0x5
    80001a98:	56c68693          	addi	a3,a3,1388 # 80007000 <_trampoline>
    80001a9c:	6605                	lui	a2,0x1
    80001a9e:	040005b7          	lui	a1,0x4000
    80001aa2:	15fd                	addi	a1,a1,-1
    80001aa4:	05b2                	slli	a1,a1,0xc
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	600080e7          	jalr	1536(ra) # 800010a6 <mappages>
    80001aae:	02054863          	bltz	a0,80001ade <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ab2:	4719                	li	a4,6
    80001ab4:	05893683          	ld	a3,88(s2)
    80001ab8:	6605                	lui	a2,0x1
    80001aba:	020005b7          	lui	a1,0x2000
    80001abe:	15fd                	addi	a1,a1,-1
    80001ac0:	05b6                	slli	a1,a1,0xd
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	fffff097          	auipc	ra,0xfffff
    80001ac8:	5e2080e7          	jalr	1506(ra) # 800010a6 <mappages>
    80001acc:	02054163          	bltz	a0,80001aee <proc_pagetable+0x76>
}
    80001ad0:	8526                	mv	a0,s1
    80001ad2:	60e2                	ld	ra,24(sp)
    80001ad4:	6442                	ld	s0,16(sp)
    80001ad6:	64a2                	ld	s1,8(sp)
    80001ad8:	6902                	ld	s2,0(sp)
    80001ada:	6105                	addi	sp,sp,32
    80001adc:	8082                	ret
    uvmfree(pagetable, 0);
    80001ade:	4581                	li	a1,0
    80001ae0:	8526                	mv	a0,s1
    80001ae2:	00000097          	auipc	ra,0x0
    80001ae6:	a52080e7          	jalr	-1454(ra) # 80001534 <uvmfree>
    return 0;
    80001aea:	4481                	li	s1,0
    80001aec:	b7d5                	j	80001ad0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aee:	4681                	li	a3,0
    80001af0:	4605                	li	a2,1
    80001af2:	040005b7          	lui	a1,0x4000
    80001af6:	15fd                	addi	a1,a1,-1
    80001af8:	05b2                	slli	a1,a1,0xc
    80001afa:	8526                	mv	a0,s1
    80001afc:	fffff097          	auipc	ra,0xfffff
    80001b00:	770080e7          	jalr	1904(ra) # 8000126c <uvmunmap>
    uvmfree(pagetable, 0);
    80001b04:	4581                	li	a1,0
    80001b06:	8526                	mv	a0,s1
    80001b08:	00000097          	auipc	ra,0x0
    80001b0c:	a2c080e7          	jalr	-1492(ra) # 80001534 <uvmfree>
    return 0;
    80001b10:	4481                	li	s1,0
    80001b12:	bf7d                	j	80001ad0 <proc_pagetable+0x58>

0000000080001b14 <proc_freepagetable>:
{
    80001b14:	1101                	addi	sp,sp,-32
    80001b16:	ec06                	sd	ra,24(sp)
    80001b18:	e822                	sd	s0,16(sp)
    80001b1a:	e426                	sd	s1,8(sp)
    80001b1c:	e04a                	sd	s2,0(sp)
    80001b1e:	1000                	addi	s0,sp,32
    80001b20:	84aa                	mv	s1,a0
    80001b22:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b24:	4681                	li	a3,0
    80001b26:	4605                	li	a2,1
    80001b28:	040005b7          	lui	a1,0x4000
    80001b2c:	15fd                	addi	a1,a1,-1
    80001b2e:	05b2                	slli	a1,a1,0xc
    80001b30:	fffff097          	auipc	ra,0xfffff
    80001b34:	73c080e7          	jalr	1852(ra) # 8000126c <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b38:	4681                	li	a3,0
    80001b3a:	4605                	li	a2,1
    80001b3c:	020005b7          	lui	a1,0x2000
    80001b40:	15fd                	addi	a1,a1,-1
    80001b42:	05b6                	slli	a1,a1,0xd
    80001b44:	8526                	mv	a0,s1
    80001b46:	fffff097          	auipc	ra,0xfffff
    80001b4a:	726080e7          	jalr	1830(ra) # 8000126c <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4e:	85ca                	mv	a1,s2
    80001b50:	8526                	mv	a0,s1
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	9e2080e7          	jalr	-1566(ra) # 80001534 <uvmfree>
}
    80001b5a:	60e2                	ld	ra,24(sp)
    80001b5c:	6442                	ld	s0,16(sp)
    80001b5e:	64a2                	ld	s1,8(sp)
    80001b60:	6902                	ld	s2,0(sp)
    80001b62:	6105                	addi	sp,sp,32
    80001b64:	8082                	ret

0000000080001b66 <freeproc>:
{
    80001b66:	1101                	addi	sp,sp,-32
    80001b68:	ec06                	sd	ra,24(sp)
    80001b6a:	e822                	sd	s0,16(sp)
    80001b6c:	e426                	sd	s1,8(sp)
    80001b6e:	1000                	addi	s0,sp,32
    80001b70:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b72:	6d28                	ld	a0,88(a0)
    80001b74:	c509                	beqz	a0,80001b7e <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b76:	fffff097          	auipc	ra,0xfffff
    80001b7a:	e74080e7          	jalr	-396(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001b7e:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b82:	68a8                	ld	a0,80(s1)
    80001b84:	c511                	beqz	a0,80001b90 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b86:	64ac                	ld	a1,72(s1)
    80001b88:	00000097          	auipc	ra,0x0
    80001b8c:	f8c080e7          	jalr	-116(ra) # 80001b14 <proc_freepagetable>
  p->pagetable = 0;
    80001b90:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b94:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b98:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b9c:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ba0:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bac:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bb0:	0004ac23          	sw	zero,24(s1)
}
    80001bb4:	60e2                	ld	ra,24(sp)
    80001bb6:	6442                	ld	s0,16(sp)
    80001bb8:	64a2                	ld	s1,8(sp)
    80001bba:	6105                	addi	sp,sp,32
    80001bbc:	8082                	ret

0000000080001bbe <allocproc>:
{
    80001bbe:	1101                	addi	sp,sp,-32
    80001bc0:	ec06                	sd	ra,24(sp)
    80001bc2:	e822                	sd	s0,16(sp)
    80001bc4:	e426                	sd	s1,8(sp)
    80001bc6:	e04a                	sd	s2,0(sp)
    80001bc8:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bca:	0000f497          	auipc	s1,0xf
    80001bce:	3e648493          	addi	s1,s1,998 # 80010fb0 <proc>
    80001bd2:	00016917          	auipc	s2,0x16
    80001bd6:	fde90913          	addi	s2,s2,-34 # 80017bb0 <tickslock>
    acquire(&p->lock);
    80001bda:	8526                	mv	a0,s1
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	ffa080e7          	jalr	-6(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001be4:	4c9c                	lw	a5,24(s1)
    80001be6:	cf81                	beqz	a5,80001bfe <allocproc+0x40>
      release(&p->lock);
    80001be8:	8526                	mv	a0,s1
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	0a0080e7          	jalr	160(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bf2:	1b048493          	addi	s1,s1,432
    80001bf6:	ff2492e3          	bne	s1,s2,80001bda <allocproc+0x1c>
  return 0;
    80001bfa:	4481                	li	s1,0
    80001bfc:	a0a5                	j	80001c64 <allocproc+0xa6>
  p->pid = allocpid();
    80001bfe:	00000097          	auipc	ra,0x0
    80001c02:	e34080e7          	jalr	-460(ra) # 80001a32 <allocpid>
    80001c06:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c08:	4785                	li	a5,1
    80001c0a:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	eda080e7          	jalr	-294(ra) # 80000ae6 <kalloc>
    80001c14:	892a                	mv	s2,a0
    80001c16:	eca8                	sd	a0,88(s1)
    80001c18:	cd29                	beqz	a0,80001c72 <allocproc+0xb4>
  p->pagetable = proc_pagetable(p);
    80001c1a:	8526                	mv	a0,s1
    80001c1c:	00000097          	auipc	ra,0x0
    80001c20:	e5c080e7          	jalr	-420(ra) # 80001a78 <proc_pagetable>
    80001c24:	892a                	mv	s2,a0
    80001c26:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c28:	c12d                	beqz	a0,80001c8a <allocproc+0xcc>
  memset(&p->context, 0, sizeof(p->context));
    80001c2a:	07000613          	li	a2,112
    80001c2e:	4581                	li	a1,0
    80001c30:	06048513          	addi	a0,s1,96
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	09e080e7          	jalr	158(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c3c:	00000797          	auipc	a5,0x0
    80001c40:	db078793          	addi	a5,a5,-592 # 800019ec <forkret>
    80001c44:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c46:	60bc                	ld	a5,64(s1)
    80001c48:	6705                	lui	a4,0x1
    80001c4a:	97ba                	add	a5,a5,a4
    80001c4c:	f4bc                	sd	a5,104(s1)
  p -> ps_priority = 0;
    80001c4e:	1804a823          	sw	zero,400(s1)
  p -> cfs_priority = 1; // normal priority (change to system call)
    80001c52:	4785                	li	a5,1
    80001c54:	18f4aa23          	sw	a5,404(s1)
  p -> rtime = 0; //runtime 
    80001c58:	1804bc23          	sd	zero,408(s1)
  p -> retime = 0; // runnable time 
    80001c5c:	1a04b423          	sd	zero,424(s1)
  p -> stime = 0; // sleep time 
    80001c60:	1a04b023          	sd	zero,416(s1)
}
    80001c64:	8526                	mv	a0,s1
    80001c66:	60e2                	ld	ra,24(sp)
    80001c68:	6442                	ld	s0,16(sp)
    80001c6a:	64a2                	ld	s1,8(sp)
    80001c6c:	6902                	ld	s2,0(sp)
    80001c6e:	6105                	addi	sp,sp,32
    80001c70:	8082                	ret
    freeproc(p);
    80001c72:	8526                	mv	a0,s1
    80001c74:	00000097          	auipc	ra,0x0
    80001c78:	ef2080e7          	jalr	-270(ra) # 80001b66 <freeproc>
    release(&p->lock);
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	fffff097          	auipc	ra,0xfffff
    80001c82:	00c080e7          	jalr	12(ra) # 80000c8a <release>
    return 0;
    80001c86:	84ca                	mv	s1,s2
    80001c88:	bff1                	j	80001c64 <allocproc+0xa6>
    freeproc(p);
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	00000097          	auipc	ra,0x0
    80001c90:	eda080e7          	jalr	-294(ra) # 80001b66 <freeproc>
    release(&p->lock);
    80001c94:	8526                	mv	a0,s1
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	ff4080e7          	jalr	-12(ra) # 80000c8a <release>
    return 0;
    80001c9e:	84ca                	mv	s1,s2
    80001ca0:	b7d1                	j	80001c64 <allocproc+0xa6>

0000000080001ca2 <userinit>:
{
    80001ca2:	1101                	addi	sp,sp,-32
    80001ca4:	ec06                	sd	ra,24(sp)
    80001ca6:	e822                	sd	s0,16(sp)
    80001ca8:	e426                	sd	s1,8(sp)
    80001caa:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cac:	00000097          	auipc	ra,0x0
    80001cb0:	f12080e7          	jalr	-238(ra) # 80001bbe <allocproc>
    80001cb4:	84aa                	mv	s1,a0
  initproc = p;
    80001cb6:	00007797          	auipc	a5,0x7
    80001cba:	c4a7bd23          	sd	a0,-934(a5) # 80008910 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cbe:	03400613          	li	a2,52
    80001cc2:	00007597          	auipc	a1,0x7
    80001cc6:	bbe58593          	addi	a1,a1,-1090 # 80008880 <initcode>
    80001cca:	6928                	ld	a0,80(a0)
    80001ccc:	fffff097          	auipc	ra,0xfffff
    80001cd0:	692080e7          	jalr	1682(ra) # 8000135e <uvmfirst>
  p->sz = PGSIZE;
    80001cd4:	6785                	lui	a5,0x1
    80001cd6:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cd8:	6cb8                	ld	a4,88(s1)
    80001cda:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cde:	6cb8                	ld	a4,88(s1)
    80001ce0:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ce2:	4641                	li	a2,16
    80001ce4:	00006597          	auipc	a1,0x6
    80001ce8:	51c58593          	addi	a1,a1,1308 # 80008200 <digits+0x1c0>
    80001cec:	15848513          	addi	a0,s1,344
    80001cf0:	fffff097          	auipc	ra,0xfffff
    80001cf4:	12c080e7          	jalr	300(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cf8:	00006517          	auipc	a0,0x6
    80001cfc:	51850513          	addi	a0,a0,1304 # 80008210 <digits+0x1d0>
    80001d00:	00002097          	auipc	ra,0x2
    80001d04:	7bc080e7          	jalr	1980(ra) # 800044bc <namei>
    80001d08:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d0c:	478d                	li	a5,3
    80001d0e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d10:	8526                	mv	a0,s1
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	f78080e7          	jalr	-136(ra) # 80000c8a <release>
}
    80001d1a:	60e2                	ld	ra,24(sp)
    80001d1c:	6442                	ld	s0,16(sp)
    80001d1e:	64a2                	ld	s1,8(sp)
    80001d20:	6105                	addi	sp,sp,32
    80001d22:	8082                	ret

0000000080001d24 <growproc>:
{
    80001d24:	1101                	addi	sp,sp,-32
    80001d26:	ec06                	sd	ra,24(sp)
    80001d28:	e822                	sd	s0,16(sp)
    80001d2a:	e426                	sd	s1,8(sp)
    80001d2c:	e04a                	sd	s2,0(sp)
    80001d2e:	1000                	addi	s0,sp,32
    80001d30:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d32:	00000097          	auipc	ra,0x0
    80001d36:	c82080e7          	jalr	-894(ra) # 800019b4 <myproc>
    80001d3a:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d3c:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d3e:	01204c63          	bgtz	s2,80001d56 <growproc+0x32>
  else if (n < 0)
    80001d42:	02094663          	bltz	s2,80001d6e <growproc+0x4a>
  p->sz = sz;
    80001d46:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d48:	4501                	li	a0,0
}
    80001d4a:	60e2                	ld	ra,24(sp)
    80001d4c:	6442                	ld	s0,16(sp)
    80001d4e:	64a2                	ld	s1,8(sp)
    80001d50:	6902                	ld	s2,0(sp)
    80001d52:	6105                	addi	sp,sp,32
    80001d54:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d56:	4691                	li	a3,4
    80001d58:	00b90633          	add	a2,s2,a1
    80001d5c:	6928                	ld	a0,80(a0)
    80001d5e:	fffff097          	auipc	ra,0xfffff
    80001d62:	6ba080e7          	jalr	1722(ra) # 80001418 <uvmalloc>
    80001d66:	85aa                	mv	a1,a0
    80001d68:	fd79                	bnez	a0,80001d46 <growproc+0x22>
      return -1;
    80001d6a:	557d                	li	a0,-1
    80001d6c:	bff9                	j	80001d4a <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d6e:	00b90633          	add	a2,s2,a1
    80001d72:	6928                	ld	a0,80(a0)
    80001d74:	fffff097          	auipc	ra,0xfffff
    80001d78:	65c080e7          	jalr	1628(ra) # 800013d0 <uvmdealloc>
    80001d7c:	85aa                	mv	a1,a0
    80001d7e:	b7e1                	j	80001d46 <growproc+0x22>

0000000080001d80 <fork>:
{
    80001d80:	7139                	addi	sp,sp,-64
    80001d82:	fc06                	sd	ra,56(sp)
    80001d84:	f822                	sd	s0,48(sp)
    80001d86:	f426                	sd	s1,40(sp)
    80001d88:	f04a                	sd	s2,32(sp)
    80001d8a:	ec4e                	sd	s3,24(sp)
    80001d8c:	e852                	sd	s4,16(sp)
    80001d8e:	e456                	sd	s5,8(sp)
    80001d90:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d92:	00000097          	auipc	ra,0x0
    80001d96:	c22080e7          	jalr	-990(ra) # 800019b4 <myproc>
    80001d9a:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001d9c:	00000097          	auipc	ra,0x0
    80001da0:	e22080e7          	jalr	-478(ra) # 80001bbe <allocproc>
    80001da4:	12050c63          	beqz	a0,80001edc <fork+0x15c>
    80001da8:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001daa:	048ab603          	ld	a2,72(s5)
    80001dae:	692c                	ld	a1,80(a0)
    80001db0:	050ab503          	ld	a0,80(s5)
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	7b8080e7          	jalr	1976(ra) # 8000156c <uvmcopy>
    80001dbc:	04054863          	bltz	a0,80001e0c <fork+0x8c>
  np->sz = p->sz;
    80001dc0:	048ab783          	ld	a5,72(s5)
    80001dc4:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dc8:	058ab683          	ld	a3,88(s5)
    80001dcc:	87b6                	mv	a5,a3
    80001dce:	0589b703          	ld	a4,88(s3)
    80001dd2:	12068693          	addi	a3,a3,288
    80001dd6:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dda:	6788                	ld	a0,8(a5)
    80001ddc:	6b8c                	ld	a1,16(a5)
    80001dde:	6f90                	ld	a2,24(a5)
    80001de0:	01073023          	sd	a6,0(a4)
    80001de4:	e708                	sd	a0,8(a4)
    80001de6:	eb0c                	sd	a1,16(a4)
    80001de8:	ef10                	sd	a2,24(a4)
    80001dea:	02078793          	addi	a5,a5,32
    80001dee:	02070713          	addi	a4,a4,32
    80001df2:	fed792e3          	bne	a5,a3,80001dd6 <fork+0x56>
  np->trapframe->a0 = 0;
    80001df6:	0589b783          	ld	a5,88(s3)
    80001dfa:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001dfe:	0d0a8493          	addi	s1,s5,208
    80001e02:	0d098913          	addi	s2,s3,208
    80001e06:	150a8a13          	addi	s4,s5,336
    80001e0a:	a00d                	j	80001e2c <fork+0xac>
    freeproc(np);
    80001e0c:	854e                	mv	a0,s3
    80001e0e:	00000097          	auipc	ra,0x0
    80001e12:	d58080e7          	jalr	-680(ra) # 80001b66 <freeproc>
    release(&np->lock);
    80001e16:	854e                	mv	a0,s3
    80001e18:	fffff097          	auipc	ra,0xfffff
    80001e1c:	e72080e7          	jalr	-398(ra) # 80000c8a <release>
    return -1;
    80001e20:	597d                	li	s2,-1
    80001e22:	a05d                	j	80001ec8 <fork+0x148>
  for (i = 0; i < NOFILE; i++)
    80001e24:	04a1                	addi	s1,s1,8
    80001e26:	0921                	addi	s2,s2,8
    80001e28:	01448b63          	beq	s1,s4,80001e3e <fork+0xbe>
    if (p->ofile[i])
    80001e2c:	6088                	ld	a0,0(s1)
    80001e2e:	d97d                	beqz	a0,80001e24 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e30:	00003097          	auipc	ra,0x3
    80001e34:	d22080e7          	jalr	-734(ra) # 80004b52 <filedup>
    80001e38:	00a93023          	sd	a0,0(s2)
    80001e3c:	b7e5                	j	80001e24 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e3e:	150ab503          	ld	a0,336(s5)
    80001e42:	00002097          	auipc	ra,0x2
    80001e46:	e96080e7          	jalr	-362(ra) # 80003cd8 <idup>
    80001e4a:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e4e:	4641                	li	a2,16
    80001e50:	158a8593          	addi	a1,s5,344
    80001e54:	15898513          	addi	a0,s3,344
    80001e58:	fffff097          	auipc	ra,0xfffff
    80001e5c:	fc4080e7          	jalr	-60(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e60:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001e64:	854e                	mv	a0,s3
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	e24080e7          	jalr	-476(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e6e:	0000f497          	auipc	s1,0xf
    80001e72:	d2a48493          	addi	s1,s1,-726 # 80010b98 <wait_lock>
    80001e76:	8526                	mv	a0,s1
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	d5e080e7          	jalr	-674(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e80:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001e84:	8526                	mv	a0,s1
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	e04080e7          	jalr	-508(ra) # 80000c8a <release>
  acquire(&np->lock); 
    80001e8e:	854e                	mv	a0,s3
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	d46080e7          	jalr	-698(ra) # 80000bd6 <acquire>
  struct proc* parent = np -> parent;
    80001e98:	0389b483          	ld	s1,56(s3)
  acquire(&parent-> lock);
    80001e9c:	8526                	mv	a0,s1
    80001e9e:	fffff097          	auipc	ra,0xfffff
    80001ea2:	d38080e7          	jalr	-712(ra) # 80000bd6 <acquire>
  np -> cfs_priority = parent -> cfs_priority; 
    80001ea6:	1944a783          	lw	a5,404(s1)
    80001eaa:	18f9aa23          	sw	a5,404(s3)
  release (&parent -> lock); 
    80001eae:	8526                	mv	a0,s1
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	dda080e7          	jalr	-550(ra) # 80000c8a <release>
  np->state = RUNNABLE;
    80001eb8:	478d                	li	a5,3
    80001eba:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ebe:	854e                	mv	a0,s3
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	dca080e7          	jalr	-566(ra) # 80000c8a <release>
}
    80001ec8:	854a                	mv	a0,s2
    80001eca:	70e2                	ld	ra,56(sp)
    80001ecc:	7442                	ld	s0,48(sp)
    80001ece:	74a2                	ld	s1,40(sp)
    80001ed0:	7902                	ld	s2,32(sp)
    80001ed2:	69e2                	ld	s3,24(sp)
    80001ed4:	6a42                	ld	s4,16(sp)
    80001ed6:	6aa2                	ld	s5,8(sp)
    80001ed8:	6121                	addi	sp,sp,64
    80001eda:	8082                	ret
    return -1;
    80001edc:	597d                	li	s2,-1
    80001ede:	b7ed                	j	80001ec8 <fork+0x148>

0000000080001ee0 <find_minimum>:
{
    80001ee0:	7139                	addi	sp,sp,-64
    80001ee2:	fc06                	sd	ra,56(sp)
    80001ee4:	f822                	sd	s0,48(sp)
    80001ee6:	f426                	sd	s1,40(sp)
    80001ee8:	f04a                	sd	s2,32(sp)
    80001eea:	ec4e                	sd	s3,24(sp)
    80001eec:	e852                	sd	s4,16(sp)
    80001eee:	e456                	sd	s5,8(sp)
    80001ef0:	0080                	addi	s0,sp,64
  long long minimum = -1; 
    80001ef2:	5a7d                	li	s4,-1
   for (p = proc; p < &proc[NPROC]; p++)
    80001ef4:	0000f497          	auipc	s1,0xf
    80001ef8:	0bc48493          	addi	s1,s1,188 # 80010fb0 <proc>
       if( p -> state == RUNNABLE)
    80001efc:	498d                	li	s3,3
        if ( minimum == -1 || p->accumulator < minimum )
    80001efe:	5afd                	li	s5,-1
   for (p = proc; p < &proc[NPROC]; p++)
    80001f00:	00016917          	auipc	s2,0x16
    80001f04:	cb090913          	addi	s2,s2,-848 # 80017bb0 <tickslock>
    80001f08:	a821                	j	80001f20 <find_minimum+0x40>
          minimum = p-> accumulator; 
    80001f0a:	1884ba03          	ld	s4,392(s1)
       release(&p->lock);
    80001f0e:	8526                	mv	a0,s1
    80001f10:	fffff097          	auipc	ra,0xfffff
    80001f14:	d7a080e7          	jalr	-646(ra) # 80000c8a <release>
   for (p = proc; p < &proc[NPROC]; p++)
    80001f18:	1b048493          	addi	s1,s1,432
    80001f1c:	03248163          	beq	s1,s2,80001f3e <find_minimum+0x5e>
       acquire(&p->lock);
    80001f20:	8526                	mv	a0,s1
    80001f22:	fffff097          	auipc	ra,0xfffff
    80001f26:	cb4080e7          	jalr	-844(ra) # 80000bd6 <acquire>
       if( p -> state == RUNNABLE)
    80001f2a:	4c9c                	lw	a5,24(s1)
    80001f2c:	ff3791e3          	bne	a5,s3,80001f0e <find_minimum+0x2e>
        if ( minimum == -1 || p->accumulator < minimum )
    80001f30:	fd5a0de3          	beq	s4,s5,80001f0a <find_minimum+0x2a>
    80001f34:	1884b783          	ld	a5,392(s1)
    80001f38:	fd47dbe3          	bge	a5,s4,80001f0e <find_minimum+0x2e>
    80001f3c:	b7f9                	j	80001f0a <find_minimum+0x2a>
}
    80001f3e:	8552                	mv	a0,s4
    80001f40:	70e2                	ld	ra,56(sp)
    80001f42:	7442                	ld	s0,48(sp)
    80001f44:	74a2                	ld	s1,40(sp)
    80001f46:	7902                	ld	s2,32(sp)
    80001f48:	69e2                	ld	s3,24(sp)
    80001f4a:	6a42                	ld	s4,16(sp)
    80001f4c:	6aa2                	ld	s5,8(sp)
    80001f4e:	6121                	addi	sp,sp,64
    80001f50:	8082                	ret

0000000080001f52 <sched>:
{
    80001f52:	7179                	addi	sp,sp,-48
    80001f54:	f406                	sd	ra,40(sp)
    80001f56:	f022                	sd	s0,32(sp)
    80001f58:	ec26                	sd	s1,24(sp)
    80001f5a:	e84a                	sd	s2,16(sp)
    80001f5c:	e44e                	sd	s3,8(sp)
    80001f5e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f60:	00000097          	auipc	ra,0x0
    80001f64:	a54080e7          	jalr	-1452(ra) # 800019b4 <myproc>
    80001f68:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001f6a:	fffff097          	auipc	ra,0xfffff
    80001f6e:	bf2080e7          	jalr	-1038(ra) # 80000b5c <holding>
    80001f72:	c93d                	beqz	a0,80001fe8 <sched+0x96>
    80001f74:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001f76:	2781                	sext.w	a5,a5
    80001f78:	079e                	slli	a5,a5,0x7
    80001f7a:	0000f717          	auipc	a4,0xf
    80001f7e:	c0670713          	addi	a4,a4,-1018 # 80010b80 <pid_lock>
    80001f82:	97ba                	add	a5,a5,a4
    80001f84:	0a87a703          	lw	a4,168(a5)
    80001f88:	4785                	li	a5,1
    80001f8a:	06f71763          	bne	a4,a5,80001ff8 <sched+0xa6>
  if (p->state == RUNNING)
    80001f8e:	4c98                	lw	a4,24(s1)
    80001f90:	4791                	li	a5,4
    80001f92:	06f70b63          	beq	a4,a5,80002008 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f96:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f9a:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001f9c:	efb5                	bnez	a5,80002018 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f9e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fa0:	0000f917          	auipc	s2,0xf
    80001fa4:	be090913          	addi	s2,s2,-1056 # 80010b80 <pid_lock>
    80001fa8:	2781                	sext.w	a5,a5
    80001faa:	079e                	slli	a5,a5,0x7
    80001fac:	97ca                	add	a5,a5,s2
    80001fae:	0ac7a983          	lw	s3,172(a5)
    80001fb2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fb4:	2781                	sext.w	a5,a5
    80001fb6:	079e                	slli	a5,a5,0x7
    80001fb8:	0000f597          	auipc	a1,0xf
    80001fbc:	c0058593          	addi	a1,a1,-1024 # 80010bb8 <cpus+0x8>
    80001fc0:	95be                	add	a1,a1,a5
    80001fc2:	06048513          	addi	a0,s1,96
    80001fc6:	00001097          	auipc	ra,0x1
    80001fca:	b62080e7          	jalr	-1182(ra) # 80002b28 <swtch>
    80001fce:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fd0:	2781                	sext.w	a5,a5
    80001fd2:	079e                	slli	a5,a5,0x7
    80001fd4:	97ca                	add	a5,a5,s2
    80001fd6:	0b37a623          	sw	s3,172(a5)
}
    80001fda:	70a2                	ld	ra,40(sp)
    80001fdc:	7402                	ld	s0,32(sp)
    80001fde:	64e2                	ld	s1,24(sp)
    80001fe0:	6942                	ld	s2,16(sp)
    80001fe2:	69a2                	ld	s3,8(sp)
    80001fe4:	6145                	addi	sp,sp,48
    80001fe6:	8082                	ret
    panic("sched p->lock");
    80001fe8:	00006517          	auipc	a0,0x6
    80001fec:	23050513          	addi	a0,a0,560 # 80008218 <digits+0x1d8>
    80001ff0:	ffffe097          	auipc	ra,0xffffe
    80001ff4:	54e080e7          	jalr	1358(ra) # 8000053e <panic>
    panic("sched locks");
    80001ff8:	00006517          	auipc	a0,0x6
    80001ffc:	23050513          	addi	a0,a0,560 # 80008228 <digits+0x1e8>
    80002000:	ffffe097          	auipc	ra,0xffffe
    80002004:	53e080e7          	jalr	1342(ra) # 8000053e <panic>
    panic("sched running");
    80002008:	00006517          	auipc	a0,0x6
    8000200c:	23050513          	addi	a0,a0,560 # 80008238 <digits+0x1f8>
    80002010:	ffffe097          	auipc	ra,0xffffe
    80002014:	52e080e7          	jalr	1326(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002018:	00006517          	auipc	a0,0x6
    8000201c:	23050513          	addi	a0,a0,560 # 80008248 <digits+0x208>
    80002020:	ffffe097          	auipc	ra,0xffffe
    80002024:	51e080e7          	jalr	1310(ra) # 8000053e <panic>

0000000080002028 <yield>:
{
    80002028:	1101                	addi	sp,sp,-32
    8000202a:	ec06                	sd	ra,24(sp)
    8000202c:	e822                	sd	s0,16(sp)
    8000202e:	e426                	sd	s1,8(sp)
    80002030:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002032:	00000097          	auipc	ra,0x0
    80002036:	982080e7          	jalr	-1662(ra) # 800019b4 <myproc>
    8000203a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	b9a080e7          	jalr	-1126(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002044:	478d                	li	a5,3
    80002046:	cc9c                	sw	a5,24(s1)
  sched();
    80002048:	00000097          	auipc	ra,0x0
    8000204c:	f0a080e7          	jalr	-246(ra) # 80001f52 <sched>
  release(&p->lock);
    80002050:	8526                	mv	a0,s1
    80002052:	fffff097          	auipc	ra,0xfffff
    80002056:	c38080e7          	jalr	-968(ra) # 80000c8a <release>
}
    8000205a:	60e2                	ld	ra,24(sp)
    8000205c:	6442                	ld	s0,16(sp)
    8000205e:	64a2                	ld	s1,8(sp)
    80002060:	6105                	addi	sp,sp,32
    80002062:	8082                	ret

0000000080002064 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002064:	7179                	addi	sp,sp,-48
    80002066:	f406                	sd	ra,40(sp)
    80002068:	f022                	sd	s0,32(sp)
    8000206a:	ec26                	sd	s1,24(sp)
    8000206c:	e84a                	sd	s2,16(sp)
    8000206e:	e44e                	sd	s3,8(sp)
    80002070:	1800                	addi	s0,sp,48
    80002072:	89aa                	mv	s3,a0
    80002074:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002076:	00000097          	auipc	ra,0x0
    8000207a:	93e080e7          	jalr	-1730(ra) # 800019b4 <myproc>
    8000207e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002080:	fffff097          	auipc	ra,0xfffff
    80002084:	b56080e7          	jalr	-1194(ra) # 80000bd6 <acquire>
  release(lk);
    80002088:	854a                	mv	a0,s2
    8000208a:	fffff097          	auipc	ra,0xfffff
    8000208e:	c00080e7          	jalr	-1024(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002092:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002096:	4789                	li	a5,2
    80002098:	cc9c                	sw	a5,24(s1)

  sched();
    8000209a:	00000097          	auipc	ra,0x0
    8000209e:	eb8080e7          	jalr	-328(ra) # 80001f52 <sched>

  // Tidy up.
  p->chan = 0;
    800020a2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020a6:	8526                	mv	a0,s1
    800020a8:	fffff097          	auipc	ra,0xfffff
    800020ac:	be2080e7          	jalr	-1054(ra) # 80000c8a <release>
  acquire(lk);
    800020b0:	854a                	mv	a0,s2
    800020b2:	fffff097          	auipc	ra,0xfffff
    800020b6:	b24080e7          	jalr	-1244(ra) # 80000bd6 <acquire>
}
    800020ba:	70a2                	ld	ra,40(sp)
    800020bc:	7402                	ld	s0,32(sp)
    800020be:	64e2                	ld	s1,24(sp)
    800020c0:	6942                	ld	s2,16(sp)
    800020c2:	69a2                	ld	s3,8(sp)
    800020c4:	6145                	addi	sp,sp,48
    800020c6:	8082                	ret

00000000800020c8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800020c8:	7139                	addi	sp,sp,-64
    800020ca:	fc06                	sd	ra,56(sp)
    800020cc:	f822                	sd	s0,48(sp)
    800020ce:	f426                	sd	s1,40(sp)
    800020d0:	f04a                	sd	s2,32(sp)
    800020d2:	ec4e                	sd	s3,24(sp)
    800020d4:	e852                	sd	s4,16(sp)
    800020d6:	e456                	sd	s5,8(sp)
    800020d8:	0080                	addi	s0,sp,64
    800020da:	8a2a                	mv	s4,a0
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    800020dc:	0000f497          	auipc	s1,0xf
    800020e0:	ed448493          	addi	s1,s1,-300 # 80010fb0 <proc>
  {

    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800020e4:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800020e6:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800020e8:	00016917          	auipc	s2,0x16
    800020ec:	ac890913          	addi	s2,s2,-1336 # 80017bb0 <tickslock>
    800020f0:	a811                	j	80002104 <wakeup+0x3c>
      }
      release(&p->lock);
    800020f2:	8526                	mv	a0,s1
    800020f4:	fffff097          	auipc	ra,0xfffff
    800020f8:	b96080e7          	jalr	-1130(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800020fc:	1b048493          	addi	s1,s1,432
    80002100:	03248663          	beq	s1,s2,8000212c <wakeup+0x64>
    if (p != myproc())
    80002104:	00000097          	auipc	ra,0x0
    80002108:	8b0080e7          	jalr	-1872(ra) # 800019b4 <myproc>
    8000210c:	fea488e3          	beq	s1,a0,800020fc <wakeup+0x34>
      acquire(&p->lock);
    80002110:	8526                	mv	a0,s1
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	ac4080e7          	jalr	-1340(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000211a:	4c9c                	lw	a5,24(s1)
    8000211c:	fd379be3          	bne	a5,s3,800020f2 <wakeup+0x2a>
    80002120:	709c                	ld	a5,32(s1)
    80002122:	fd4798e3          	bne	a5,s4,800020f2 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002126:	0154ac23          	sw	s5,24(s1)
    8000212a:	b7e1                	j	800020f2 <wakeup+0x2a>
    // task 6 
   // else{
      
  //  }
  }
}
    8000212c:	70e2                	ld	ra,56(sp)
    8000212e:	7442                	ld	s0,48(sp)
    80002130:	74a2                	ld	s1,40(sp)
    80002132:	7902                	ld	s2,32(sp)
    80002134:	69e2                	ld	s3,24(sp)
    80002136:	6a42                	ld	s4,16(sp)
    80002138:	6aa2                	ld	s5,8(sp)
    8000213a:	6121                	addi	sp,sp,64
    8000213c:	8082                	ret

000000008000213e <reparent>:
{
    8000213e:	7179                	addi	sp,sp,-48
    80002140:	f406                	sd	ra,40(sp)
    80002142:	f022                	sd	s0,32(sp)
    80002144:	ec26                	sd	s1,24(sp)
    80002146:	e84a                	sd	s2,16(sp)
    80002148:	e44e                	sd	s3,8(sp)
    8000214a:	e052                	sd	s4,0(sp)
    8000214c:	1800                	addi	s0,sp,48
    8000214e:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002150:	0000f497          	auipc	s1,0xf
    80002154:	e6048493          	addi	s1,s1,-416 # 80010fb0 <proc>
      pp->parent = initproc;
    80002158:	00006a17          	auipc	s4,0x6
    8000215c:	7b8a0a13          	addi	s4,s4,1976 # 80008910 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002160:	00016997          	auipc	s3,0x16
    80002164:	a5098993          	addi	s3,s3,-1456 # 80017bb0 <tickslock>
    80002168:	a029                	j	80002172 <reparent+0x34>
    8000216a:	1b048493          	addi	s1,s1,432
    8000216e:	01348d63          	beq	s1,s3,80002188 <reparent+0x4a>
    if (pp->parent == p)
    80002172:	7c9c                	ld	a5,56(s1)
    80002174:	ff279be3          	bne	a5,s2,8000216a <reparent+0x2c>
      pp->parent = initproc;
    80002178:	000a3503          	ld	a0,0(s4)
    8000217c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000217e:	00000097          	auipc	ra,0x0
    80002182:	f4a080e7          	jalr	-182(ra) # 800020c8 <wakeup>
    80002186:	b7d5                	j	8000216a <reparent+0x2c>
}
    80002188:	70a2                	ld	ra,40(sp)
    8000218a:	7402                	ld	s0,32(sp)
    8000218c:	64e2                	ld	s1,24(sp)
    8000218e:	6942                	ld	s2,16(sp)
    80002190:	69a2                	ld	s3,8(sp)
    80002192:	6a02                	ld	s4,0(sp)
    80002194:	6145                	addi	sp,sp,48
    80002196:	8082                	ret

0000000080002198 <exit>:
{
    80002198:	7179                	addi	sp,sp,-48
    8000219a:	f406                	sd	ra,40(sp)
    8000219c:	f022                	sd	s0,32(sp)
    8000219e:	ec26                	sd	s1,24(sp)
    800021a0:	e84a                	sd	s2,16(sp)
    800021a2:	e44e                	sd	s3,8(sp)
    800021a4:	e052                	sd	s4,0(sp)
    800021a6:	1800                	addi	s0,sp,48
    800021a8:	8a2a                	mv	s4,a0
    800021aa:	84ae                	mv	s1,a1
  struct proc *p = myproc();
    800021ac:	00000097          	auipc	ra,0x0
    800021b0:	808080e7          	jalr	-2040(ra) # 800019b4 <myproc>
    800021b4:	89aa                	mv	s3,a0
  safestrcpy(p->exit_msg, exit_msg, sizeof(exit_msg));
    800021b6:	4621                	li	a2,8
    800021b8:	85a6                	mv	a1,s1
    800021ba:	16850513          	addi	a0,a0,360
    800021be:	fffff097          	auipc	ra,0xfffff
    800021c2:	c5e080e7          	jalr	-930(ra) # 80000e1c <safestrcpy>
  if (p == initproc)
    800021c6:	00006797          	auipc	a5,0x6
    800021ca:	74a7b783          	ld	a5,1866(a5) # 80008910 <initproc>
    800021ce:	0d098493          	addi	s1,s3,208
    800021d2:	15098913          	addi	s2,s3,336
    800021d6:	03379363          	bne	a5,s3,800021fc <exit+0x64>
    panic("init exiting");
    800021da:	00006517          	auipc	a0,0x6
    800021de:	08650513          	addi	a0,a0,134 # 80008260 <digits+0x220>
    800021e2:	ffffe097          	auipc	ra,0xffffe
    800021e6:	35c080e7          	jalr	860(ra) # 8000053e <panic>
      fileclose(f);
    800021ea:	00003097          	auipc	ra,0x3
    800021ee:	9ba080e7          	jalr	-1606(ra) # 80004ba4 <fileclose>
      p->ofile[fd] = 0;
    800021f2:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800021f6:	04a1                	addi	s1,s1,8
    800021f8:	01248563          	beq	s1,s2,80002202 <exit+0x6a>
    if (p->ofile[fd])
    800021fc:	6088                	ld	a0,0(s1)
    800021fe:	f575                	bnez	a0,800021ea <exit+0x52>
    80002200:	bfdd                	j	800021f6 <exit+0x5e>
  begin_op();
    80002202:	00002097          	auipc	ra,0x2
    80002206:	4d6080e7          	jalr	1238(ra) # 800046d8 <begin_op>
  iput(p->cwd);
    8000220a:	1509b503          	ld	a0,336(s3)
    8000220e:	00002097          	auipc	ra,0x2
    80002212:	cc2080e7          	jalr	-830(ra) # 80003ed0 <iput>
  end_op();
    80002216:	00002097          	auipc	ra,0x2
    8000221a:	542080e7          	jalr	1346(ra) # 80004758 <end_op>
  p->cwd = 0;
    8000221e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002222:	0000f497          	auipc	s1,0xf
    80002226:	97648493          	addi	s1,s1,-1674 # 80010b98 <wait_lock>
    8000222a:	8526                	mv	a0,s1
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	9aa080e7          	jalr	-1622(ra) # 80000bd6 <acquire>
  reparent(p);
    80002234:	854e                	mv	a0,s3
    80002236:	00000097          	auipc	ra,0x0
    8000223a:	f08080e7          	jalr	-248(ra) # 8000213e <reparent>
  wakeup(p->parent);
    8000223e:	0389b503          	ld	a0,56(s3)
    80002242:	00000097          	auipc	ra,0x0
    80002246:	e86080e7          	jalr	-378(ra) # 800020c8 <wakeup>
  acquire(&p->lock);
    8000224a:	854e                	mv	a0,s3
    8000224c:	fffff097          	auipc	ra,0xfffff
    80002250:	98a080e7          	jalr	-1654(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002254:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002258:	4795                	li	a5,5
    8000225a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000225e:	8526                	mv	a0,s1
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	a2a080e7          	jalr	-1494(ra) # 80000c8a <release>
  sched();
    80002268:	00000097          	auipc	ra,0x0
    8000226c:	cea080e7          	jalr	-790(ra) # 80001f52 <sched>
  panic("zombie exit");
    80002270:	00006517          	auipc	a0,0x6
    80002274:	00050513          	mv	a0,a0
    80002278:	ffffe097          	auipc	ra,0xffffe
    8000227c:	2c6080e7          	jalr	710(ra) # 8000053e <panic>

0000000080002280 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002280:	7179                	addi	sp,sp,-48
    80002282:	f406                	sd	ra,40(sp)
    80002284:	f022                	sd	s0,32(sp)
    80002286:	ec26                	sd	s1,24(sp)
    80002288:	e84a                	sd	s2,16(sp)
    8000228a:	e44e                	sd	s3,8(sp)
    8000228c:	1800                	addi	s0,sp,48
    8000228e:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002290:	0000f497          	auipc	s1,0xf
    80002294:	d2048493          	addi	s1,s1,-736 # 80010fb0 <proc>
    80002298:	00016997          	auipc	s3,0x16
    8000229c:	91898993          	addi	s3,s3,-1768 # 80017bb0 <tickslock>
  {
    acquire(&p->lock);
    800022a0:	8526                	mv	a0,s1
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	934080e7          	jalr	-1740(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    800022aa:	589c                	lw	a5,48(s1)
    800022ac:	01278d63          	beq	a5,s2,800022c6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022b0:	8526                	mv	a0,s1
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9d8080e7          	jalr	-1576(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800022ba:	1b048493          	addi	s1,s1,432
    800022be:	ff3491e3          	bne	s1,s3,800022a0 <kill+0x20>
  }
  return -1;
    800022c2:	557d                	li	a0,-1
    800022c4:	a829                	j	800022de <kill+0x5e>
      p->killed = 1;
    800022c6:	4785                	li	a5,1
    800022c8:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800022ca:	4c98                	lw	a4,24(s1)
    800022cc:	4789                	li	a5,2
    800022ce:	00f70f63          	beq	a4,a5,800022ec <kill+0x6c>
      release(&p->lock);
    800022d2:	8526                	mv	a0,s1
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	9b6080e7          	jalr	-1610(ra) # 80000c8a <release>
      return 0;
    800022dc:	4501                	li	a0,0
}
    800022de:	70a2                	ld	ra,40(sp)
    800022e0:	7402                	ld	s0,32(sp)
    800022e2:	64e2                	ld	s1,24(sp)
    800022e4:	6942                	ld	s2,16(sp)
    800022e6:	69a2                	ld	s3,8(sp)
    800022e8:	6145                	addi	sp,sp,48
    800022ea:	8082                	ret
        p->state = RUNNABLE;
    800022ec:	478d                	li	a5,3
    800022ee:	cc9c                	sw	a5,24(s1)
    800022f0:	b7cd                	j	800022d2 <kill+0x52>

00000000800022f2 <setkilled>:

void setkilled(struct proc *p)
{
    800022f2:	1101                	addi	sp,sp,-32
    800022f4:	ec06                	sd	ra,24(sp)
    800022f6:	e822                	sd	s0,16(sp)
    800022f8:	e426                	sd	s1,8(sp)
    800022fa:	1000                	addi	s0,sp,32
    800022fc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	8d8080e7          	jalr	-1832(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002306:	4785                	li	a5,1
    80002308:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000230a:	8526                	mv	a0,s1
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	97e080e7          	jalr	-1666(ra) # 80000c8a <release>
}
    80002314:	60e2                	ld	ra,24(sp)
    80002316:	6442                	ld	s0,16(sp)
    80002318:	64a2                	ld	s1,8(sp)
    8000231a:	6105                	addi	sp,sp,32
    8000231c:	8082                	ret

000000008000231e <killed>:

int killed(struct proc *p)
{
    8000231e:	1101                	addi	sp,sp,-32
    80002320:	ec06                	sd	ra,24(sp)
    80002322:	e822                	sd	s0,16(sp)
    80002324:	e426                	sd	s1,8(sp)
    80002326:	e04a                	sd	s2,0(sp)
    80002328:	1000                	addi	s0,sp,32
    8000232a:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	8aa080e7          	jalr	-1878(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002334:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002338:	8526                	mv	a0,s1
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	950080e7          	jalr	-1712(ra) # 80000c8a <release>
  return k;
}
    80002342:	854a                	mv	a0,s2
    80002344:	60e2                	ld	ra,24(sp)
    80002346:	6442                	ld	s0,16(sp)
    80002348:	64a2                	ld	s1,8(sp)
    8000234a:	6902                	ld	s2,0(sp)
    8000234c:	6105                	addi	sp,sp,32
    8000234e:	8082                	ret

0000000080002350 <wait>:
{
    80002350:	711d                	addi	sp,sp,-96
    80002352:	ec86                	sd	ra,88(sp)
    80002354:	e8a2                	sd	s0,80(sp)
    80002356:	e4a6                	sd	s1,72(sp)
    80002358:	e0ca                	sd	s2,64(sp)
    8000235a:	fc4e                	sd	s3,56(sp)
    8000235c:	f852                	sd	s4,48(sp)
    8000235e:	f456                	sd	s5,40(sp)
    80002360:	f05a                	sd	s6,32(sp)
    80002362:	ec5e                	sd	s7,24(sp)
    80002364:	e862                	sd	s8,16(sp)
    80002366:	e466                	sd	s9,8(sp)
    80002368:	1080                	addi	s0,sp,96
    8000236a:	8baa                	mv	s7,a0
    8000236c:	8a2e                	mv	s4,a1
  struct proc *p = myproc();
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	646080e7          	jalr	1606(ra) # 800019b4 <myproc>
    80002376:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002378:	0000f517          	auipc	a0,0xf
    8000237c:	82050513          	addi	a0,a0,-2016 # 80010b98 <wait_lock>
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	856080e7          	jalr	-1962(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002388:	4c01                	li	s8,0
        if (pp->state == ZOMBIE)
    8000238a:	4a95                	li	s5,5
        havekids = 1;
    8000238c:	4b05                	li	s6,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000238e:	00016997          	auipc	s3,0x16
    80002392:	82298993          	addi	s3,s3,-2014 # 80017bb0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002396:	0000fc97          	auipc	s9,0xf
    8000239a:	802c8c93          	addi	s9,s9,-2046 # 80010b98 <wait_lock>
    havekids = 0;
    8000239e:	8762                	mv	a4,s8
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023a0:	0000f497          	auipc	s1,0xf
    800023a4:	c1048493          	addi	s1,s1,-1008 # 80010fb0 <proc>
    800023a8:	a831                	j	800023c4 <wait+0x74>
        if (pp->state == ZOMBIE)
    800023aa:	4c9c                	lw	a5,24(s1)
    800023ac:	07578263          	beq	a5,s5,80002410 <wait+0xc0>
        release(&pp->lock);
    800023b0:	8526                	mv	a0,s1
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	8d8080e7          	jalr	-1832(ra) # 80000c8a <release>
        havekids = 1;
    800023ba:	875a                	mv	a4,s6
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023bc:	1b048493          	addi	s1,s1,432
    800023c0:	0b348a63          	beq	s1,s3,80002474 <wait+0x124>
      if (pp->parent == p)
    800023c4:	7c9c                	ld	a5,56(s1)
    800023c6:	ff279be3          	bne	a5,s2,800023bc <wait+0x6c>
        acquire(&pp->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	80a080e7          	jalr	-2038(ra) # 80000bd6 <acquire>
        if (addr2 != 0 && copyout(p->pagetable, addr2, (char *)&pp->exit_msg, sizeof(pp->exit_msg)) < 0 )
    800023d4:	fc0a0be3          	beqz	s4,800023aa <wait+0x5a>
    800023d8:	02000693          	li	a3,32
    800023dc:	16848613          	addi	a2,s1,360
    800023e0:	85d2                	mv	a1,s4
    800023e2:	05093503          	ld	a0,80(s2)
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	28a080e7          	jalr	650(ra) # 80001670 <copyout>
    800023ee:	fa055ee3          	bgez	a0,800023aa <wait+0x5a>
          release(&pp->lock);
    800023f2:	8526                	mv	a0,s1
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	896080e7          	jalr	-1898(ra) # 80000c8a <release>
          release(&wait_lock);
    800023fc:	0000e517          	auipc	a0,0xe
    80002400:	79c50513          	addi	a0,a0,1948 # 80010b98 <wait_lock>
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	886080e7          	jalr	-1914(ra) # 80000c8a <release>
          return -1; 
    8000240c:	59fd                	li	s3,-1
    8000240e:	a059                	j	80002494 <wait+0x144>
          pid = pp->pid;
    80002410:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate, sizeof(pp->xstate)) < 0 )
    80002414:	000b8e63          	beqz	s7,80002430 <wait+0xe0>
    80002418:	4691                	li	a3,4
    8000241a:	02c48613          	addi	a2,s1,44
    8000241e:	85de                	mv	a1,s7
    80002420:	05093503          	ld	a0,80(s2)
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	24c080e7          	jalr	588(ra) # 80001670 <copyout>
    8000242c:	02054563          	bltz	a0,80002456 <wait+0x106>
          freeproc(pp);
    80002430:	8526                	mv	a0,s1
    80002432:	fffff097          	auipc	ra,0xfffff
    80002436:	734080e7          	jalr	1844(ra) # 80001b66 <freeproc>
          release(&pp->lock);
    8000243a:	8526                	mv	a0,s1
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	84e080e7          	jalr	-1970(ra) # 80000c8a <release>
          release(&wait_lock);
    80002444:	0000e517          	auipc	a0,0xe
    80002448:	75450513          	addi	a0,a0,1876 # 80010b98 <wait_lock>
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	83e080e7          	jalr	-1986(ra) # 80000c8a <release>
          return pid;
    80002454:	a081                	j	80002494 <wait+0x144>
            release(&pp->lock);
    80002456:	8526                	mv	a0,s1
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	832080e7          	jalr	-1998(ra) # 80000c8a <release>
            release(&wait_lock);
    80002460:	0000e517          	auipc	a0,0xe
    80002464:	73850513          	addi	a0,a0,1848 # 80010b98 <wait_lock>
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	822080e7          	jalr	-2014(ra) # 80000c8a <release>
            return -1;
    80002470:	59fd                	li	s3,-1
    80002472:	a00d                	j	80002494 <wait+0x144>
    if (!havekids || killed(p))
    80002474:	c719                	beqz	a4,80002482 <wait+0x132>
    80002476:	854a                	mv	a0,s2
    80002478:	00000097          	auipc	ra,0x0
    8000247c:	ea6080e7          	jalr	-346(ra) # 8000231e <killed>
    80002480:	c905                	beqz	a0,800024b0 <wait+0x160>
      release(&wait_lock);
    80002482:	0000e517          	auipc	a0,0xe
    80002486:	71650513          	addi	a0,a0,1814 # 80010b98 <wait_lock>
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	800080e7          	jalr	-2048(ra) # 80000c8a <release>
      return -1;
    80002492:	59fd                	li	s3,-1
}
    80002494:	854e                	mv	a0,s3
    80002496:	60e6                	ld	ra,88(sp)
    80002498:	6446                	ld	s0,80(sp)
    8000249a:	64a6                	ld	s1,72(sp)
    8000249c:	6906                	ld	s2,64(sp)
    8000249e:	79e2                	ld	s3,56(sp)
    800024a0:	7a42                	ld	s4,48(sp)
    800024a2:	7aa2                	ld	s5,40(sp)
    800024a4:	7b02                	ld	s6,32(sp)
    800024a6:	6be2                	ld	s7,24(sp)
    800024a8:	6c42                	ld	s8,16(sp)
    800024aa:	6ca2                	ld	s9,8(sp)
    800024ac:	6125                	addi	sp,sp,96
    800024ae:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800024b0:	85e6                	mv	a1,s9
    800024b2:	854a                	mv	a0,s2
    800024b4:	00000097          	auipc	ra,0x0
    800024b8:	bb0080e7          	jalr	-1104(ra) # 80002064 <sleep>
    havekids = 0;
    800024bc:	b5cd                	j	8000239e <wait+0x4e>

00000000800024be <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024be:	7179                	addi	sp,sp,-48
    800024c0:	f406                	sd	ra,40(sp)
    800024c2:	f022                	sd	s0,32(sp)
    800024c4:	ec26                	sd	s1,24(sp)
    800024c6:	e84a                	sd	s2,16(sp)
    800024c8:	e44e                	sd	s3,8(sp)
    800024ca:	e052                	sd	s4,0(sp)
    800024cc:	1800                	addi	s0,sp,48
    800024ce:	84aa                	mv	s1,a0
    800024d0:	892e                	mv	s2,a1
    800024d2:	89b2                	mv	s3,a2
    800024d4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	4de080e7          	jalr	1246(ra) # 800019b4 <myproc>
  if (user_dst)
    800024de:	c08d                	beqz	s1,80002500 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800024e0:	86d2                	mv	a3,s4
    800024e2:	864e                	mv	a2,s3
    800024e4:	85ca                	mv	a1,s2
    800024e6:	6928                	ld	a0,80(a0)
    800024e8:	fffff097          	auipc	ra,0xfffff
    800024ec:	188080e7          	jalr	392(ra) # 80001670 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024f0:	70a2                	ld	ra,40(sp)
    800024f2:	7402                	ld	s0,32(sp)
    800024f4:	64e2                	ld	s1,24(sp)
    800024f6:	6942                	ld	s2,16(sp)
    800024f8:	69a2                	ld	s3,8(sp)
    800024fa:	6a02                	ld	s4,0(sp)
    800024fc:	6145                	addi	sp,sp,48
    800024fe:	8082                	ret
    memmove((char *)dst, src, len);
    80002500:	000a061b          	sext.w	a2,s4
    80002504:	85ce                	mv	a1,s3
    80002506:	854a                	mv	a0,s2
    80002508:	fffff097          	auipc	ra,0xfffff
    8000250c:	826080e7          	jalr	-2010(ra) # 80000d2e <memmove>
    return 0;
    80002510:	8526                	mv	a0,s1
    80002512:	bff9                	j	800024f0 <either_copyout+0x32>

0000000080002514 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002514:	7179                	addi	sp,sp,-48
    80002516:	f406                	sd	ra,40(sp)
    80002518:	f022                	sd	s0,32(sp)
    8000251a:	ec26                	sd	s1,24(sp)
    8000251c:	e84a                	sd	s2,16(sp)
    8000251e:	e44e                	sd	s3,8(sp)
    80002520:	e052                	sd	s4,0(sp)
    80002522:	1800                	addi	s0,sp,48
    80002524:	892a                	mv	s2,a0
    80002526:	84ae                	mv	s1,a1
    80002528:	89b2                	mv	s3,a2
    8000252a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	488080e7          	jalr	1160(ra) # 800019b4 <myproc>
  if (user_src)
    80002534:	c08d                	beqz	s1,80002556 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002536:	86d2                	mv	a3,s4
    80002538:	864e                	mv	a2,s3
    8000253a:	85ca                	mv	a1,s2
    8000253c:	6928                	ld	a0,80(a0)
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	1be080e7          	jalr	446(ra) # 800016fc <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002546:	70a2                	ld	ra,40(sp)
    80002548:	7402                	ld	s0,32(sp)
    8000254a:	64e2                	ld	s1,24(sp)
    8000254c:	6942                	ld	s2,16(sp)
    8000254e:	69a2                	ld	s3,8(sp)
    80002550:	6a02                	ld	s4,0(sp)
    80002552:	6145                	addi	sp,sp,48
    80002554:	8082                	ret
    memmove(dst, (char *)src, len);
    80002556:	000a061b          	sext.w	a2,s4
    8000255a:	85ce                	mv	a1,s3
    8000255c:	854a                	mv	a0,s2
    8000255e:	ffffe097          	auipc	ra,0xffffe
    80002562:	7d0080e7          	jalr	2000(ra) # 80000d2e <memmove>
    return 0;
    80002566:	8526                	mv	a0,s1
    80002568:	bff9                	j	80002546 <either_copyin+0x32>

000000008000256a <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000256a:	715d                	addi	sp,sp,-80
    8000256c:	e486                	sd	ra,72(sp)
    8000256e:	e0a2                	sd	s0,64(sp)
    80002570:	fc26                	sd	s1,56(sp)
    80002572:	f84a                	sd	s2,48(sp)
    80002574:	f44e                	sd	s3,40(sp)
    80002576:	f052                	sd	s4,32(sp)
    80002578:	ec56                	sd	s5,24(sp)
    8000257a:	e85a                	sd	s6,16(sp)
    8000257c:	e45e                	sd	s7,8(sp)
    8000257e:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002580:	00006517          	auipc	a0,0x6
    80002584:	b4850513          	addi	a0,a0,-1208 # 800080c8 <digits+0x88>
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	000080e7          	jalr	ra # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002590:	0000f497          	auipc	s1,0xf
    80002594:	b7848493          	addi	s1,s1,-1160 # 80011108 <proc+0x158>
    80002598:	00015917          	auipc	s2,0x15
    8000259c:	77090913          	addi	s2,s2,1904 # 80017d08 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025a2:	00006997          	auipc	s3,0x6
    800025a6:	cde98993          	addi	s3,s3,-802 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800025aa:	00006a97          	auipc	s5,0x6
    800025ae:	cdea8a93          	addi	s5,s5,-802 # 80008288 <digits+0x248>
    printf("\n");
    800025b2:	00006a17          	auipc	s4,0x6
    800025b6:	b16a0a13          	addi	s4,s4,-1258 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ba:	00006b97          	auipc	s7,0x6
    800025be:	d0eb8b93          	addi	s7,s7,-754 # 800082c8 <states.0>
    800025c2:	a00d                	j	800025e4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025c4:	ed86a583          	lw	a1,-296(a3)
    800025c8:	8556                	mv	a0,s5
    800025ca:	ffffe097          	auipc	ra,0xffffe
    800025ce:	fbe080e7          	jalr	-66(ra) # 80000588 <printf>
    printf("\n");
    800025d2:	8552                	mv	a0,s4
    800025d4:	ffffe097          	auipc	ra,0xffffe
    800025d8:	fb4080e7          	jalr	-76(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800025dc:	1b048493          	addi	s1,s1,432
    800025e0:	03248163          	beq	s1,s2,80002602 <procdump+0x98>
    if (p->state == UNUSED)
    800025e4:	86a6                	mv	a3,s1
    800025e6:	ec04a783          	lw	a5,-320(s1)
    800025ea:	dbed                	beqz	a5,800025dc <procdump+0x72>
      state = "???";
    800025ec:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ee:	fcfb6be3          	bltu	s6,a5,800025c4 <procdump+0x5a>
    800025f2:	1782                	slli	a5,a5,0x20
    800025f4:	9381                	srli	a5,a5,0x20
    800025f6:	078e                	slli	a5,a5,0x3
    800025f8:	97de                	add	a5,a5,s7
    800025fa:	6390                	ld	a2,0(a5)
    800025fc:	f661                	bnez	a2,800025c4 <procdump+0x5a>
      state = "???";
    800025fe:	864e                	mv	a2,s3
    80002600:	b7d1                	j	800025c4 <procdump+0x5a>
  }
}
    80002602:	60a6                	ld	ra,72(sp)
    80002604:	6406                	ld	s0,64(sp)
    80002606:	74e2                	ld	s1,56(sp)
    80002608:	7942                	ld	s2,48(sp)
    8000260a:	79a2                	ld	s3,40(sp)
    8000260c:	7a02                	ld	s4,32(sp)
    8000260e:	6ae2                	ld	s5,24(sp)
    80002610:	6b42                	ld	s6,16(sp)
    80002612:	6ba2                	ld	s7,8(sp)
    80002614:	6161                	addi	sp,sp,80
    80002616:	8082                	ret

0000000080002618 <set_ps_priority>:

// task 5 
void set_ps_priority(int priority){
    80002618:	1101                	addi	sp,sp,-32
    8000261a:	ec06                	sd	ra,24(sp)
    8000261c:	e822                	sd	s0,16(sp)
    8000261e:	e426                	sd	s1,8(sp)
    80002620:	1000                	addi	s0,sp,32
    80002622:	84aa                	mv	s1,a0
  acquire(&myproc()->lock);
    80002624:	fffff097          	auipc	ra,0xfffff
    80002628:	390080e7          	jalr	912(ra) # 800019b4 <myproc>
    8000262c:	ffffe097          	auipc	ra,0xffffe
    80002630:	5aa080e7          	jalr	1450(ra) # 80000bd6 <acquire>
  myproc() -> ps_priority = priority; 
    80002634:	fffff097          	auipc	ra,0xfffff
    80002638:	380080e7          	jalr	896(ra) # 800019b4 <myproc>
    8000263c:	18952823          	sw	s1,400(a0)
  release(&myproc()->lock); 
    80002640:	fffff097          	auipc	ra,0xfffff
    80002644:	374080e7          	jalr	884(ra) # 800019b4 <myproc>
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	642080e7          	jalr	1602(ra) # 80000c8a <release>
  return;
}
    80002650:	60e2                	ld	ra,24(sp)
    80002652:	6442                	ld	s0,16(sp)
    80002654:	64a2                	ld	s1,8(sp)
    80002656:	6105                	addi	sp,sp,32
    80002658:	8082                	ret

000000008000265a <check_vruntime>:


long check_vruntime(struct proc *p)
{
    8000265a:	1141                	addi	sp,sp,-16
    8000265c:	e422                	sd	s0,8(sp)
    8000265e:	0800                	addi	s0,sp,16
  long virtual_time = (p -> rtime) / (p -> rtime + p -> retime + p-> stime);
    80002660:	19853783          	ld	a5,408(a0)
    80002664:	1a853703          	ld	a4,424(a0)
    80002668:	973e                	add	a4,a4,a5
    8000266a:	1a053683          	ld	a3,416(a0)
    8000266e:	9736                	add	a4,a4,a3
    80002670:	02e7c7b3          	div	a5,a5,a4
  if (p -> cfs_priority == 0){
    80002674:	19452703          	lw	a4,404(a0)
    80002678:	cf01                	beqz	a4,80002690 <check_vruntime+0x36>
    return 75 * virtual_time;
  }
  if (p -> cfs_priority == 1){
    8000267a:	4685                	li	a3,1
    8000267c:	02d70163          	beq	a4,a3,8000269e <check_vruntime+0x44>
    return 100 * virtual_time;
  }
  else{
    return 125 * virtual_time;
    80002680:	00579513          	slli	a0,a5,0x5
    80002684:	8d1d                	sub	a0,a0,a5
    80002686:	050a                	slli	a0,a0,0x2
    80002688:	953e                	add	a0,a0,a5
  }
}
    8000268a:	6422                	ld	s0,8(sp)
    8000268c:	0141                	addi	sp,sp,16
    8000268e:	8082                	ret
    return 75 * virtual_time;
    80002690:	00279513          	slli	a0,a5,0x2
    80002694:	97aa                	add	a5,a5,a0
    80002696:	00479513          	slli	a0,a5,0x4
    8000269a:	8d1d                	sub	a0,a0,a5
    8000269c:	b7fd                	j	8000268a <check_vruntime+0x30>
    return 100 * virtual_time;
    8000269e:	06400513          	li	a0,100
    800026a2:	02a78533          	mul	a0,a5,a0
    800026a6:	b7d5                	j	8000268a <check_vruntime+0x30>

00000000800026a8 <minimum_vruntime>:

long minimum_vruntime()
{
    800026a8:	7139                	addi	sp,sp,-64
    800026aa:	fc06                	sd	ra,56(sp)
    800026ac:	f822                	sd	s0,48(sp)
    800026ae:	f426                	sd	s1,40(sp)
    800026b0:	f04a                	sd	s2,32(sp)
    800026b2:	ec4e                	sd	s3,24(sp)
    800026b4:	e852                	sd	s4,16(sp)
    800026b6:	e456                	sd	s5,8(sp)
    800026b8:	0080                	addi	s0,sp,64
  struct proc *p;
  long minimum = -1; 
    800026ba:	5a7d                	li	s4,-1
  long virtual_time = 0 ; 
  for (p = proc; p < &proc[NPROC]; p++)
    800026bc:	0000f497          	auipc	s1,0xf
    800026c0:	8f448493          	addi	s1,s1,-1804 # 80010fb0 <proc>
    {
       acquire(&p->lock);
       if( p -> state == RUNNABLE)
    800026c4:	498d                	li	s3,3
       {
        virtual_time = check_vruntime(p);
        if ( minimum == -1 || virtual_time < minimum )
    800026c6:	5afd                	li	s5,-1
  for (p = proc; p < &proc[NPROC]; p++)
    800026c8:	00015917          	auipc	s2,0x15
    800026cc:	4e890913          	addi	s2,s2,1256 # 80017bb0 <tickslock>
    800026d0:	a819                	j	800026e6 <minimum_vruntime+0x3e>
        {
          minimum = virtual_time; 
    800026d2:	8a2a                	mv	s4,a0
        }
       }
       release(&p->lock);
    800026d4:	8526                	mv	a0,s1
    800026d6:	ffffe097          	auipc	ra,0xffffe
    800026da:	5b4080e7          	jalr	1460(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800026de:	1b048493          	addi	s1,s1,432
    800026e2:	03248563          	beq	s1,s2,8000270c <minimum_vruntime+0x64>
       acquire(&p->lock);
    800026e6:	8526                	mv	a0,s1
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	4ee080e7          	jalr	1262(ra) # 80000bd6 <acquire>
       if( p -> state == RUNNABLE)
    800026f0:	4c9c                	lw	a5,24(s1)
    800026f2:	ff3791e3          	bne	a5,s3,800026d4 <minimum_vruntime+0x2c>
        virtual_time = check_vruntime(p);
    800026f6:	8526                	mv	a0,s1
    800026f8:	00000097          	auipc	ra,0x0
    800026fc:	f62080e7          	jalr	-158(ra) # 8000265a <check_vruntime>
        if ( minimum == -1 || virtual_time < minimum )
    80002700:	fd5a09e3          	beq	s4,s5,800026d2 <minimum_vruntime+0x2a>
    80002704:	fd4558e3          	bge	a0,s4,800026d4 <minimum_vruntime+0x2c>
    80002708:	8a2a                	mv	s4,a0
    8000270a:	b7e9                	j	800026d4 <minimum_vruntime+0x2c>
    }
    return minimum;
}
    8000270c:	8552                	mv	a0,s4
    8000270e:	70e2                	ld	ra,56(sp)
    80002710:	7442                	ld	s0,48(sp)
    80002712:	74a2                	ld	s1,40(sp)
    80002714:	7902                	ld	s2,32(sp)
    80002716:	69e2                	ld	s3,24(sp)
    80002718:	6a42                	ld	s4,16(sp)
    8000271a:	6aa2                	ld	s5,8(sp)
    8000271c:	6121                	addi	sp,sp,64
    8000271e:	8082                	ret

0000000080002720 <schedulerCFS>:
{
    80002720:	711d                	addi	sp,sp,-96
    80002722:	ec86                	sd	ra,88(sp)
    80002724:	e8a2                	sd	s0,80(sp)
    80002726:	e4a6                	sd	s1,72(sp)
    80002728:	e0ca                	sd	s2,64(sp)
    8000272a:	fc4e                	sd	s3,56(sp)
    8000272c:	f852                	sd	s4,48(sp)
    8000272e:	f456                	sd	s5,40(sp)
    80002730:	f05a                	sd	s6,32(sp)
    80002732:	ec5e                	sd	s7,24(sp)
    80002734:	e862                	sd	s8,16(sp)
    80002736:	e466                	sd	s9,8(sp)
    80002738:	e06a                	sd	s10,0(sp)
    8000273a:	1080                	addi	s0,sp,96
    8000273c:	8492                	mv	s1,tp
  int id = r_tp();
    8000273e:	2481                	sext.w	s1,s1
  long minimum = minimum_vruntime();
    80002740:	00000097          	auipc	ra,0x0
    80002744:	f68080e7          	jalr	-152(ra) # 800026a8 <minimum_vruntime>
    80002748:	892a                	mv	s2,a0
  c->proc = 0;
    8000274a:	00749c13          	slli	s8,s1,0x7
    8000274e:	0000e797          	auipc	a5,0xe
    80002752:	43278793          	addi	a5,a5,1074 # 80010b80 <pid_lock>
    80002756:	97e2                	add	a5,a5,s8
    80002758:	0207b823          	sd	zero,48(a5)
        swtch(&c->context, &p->context);
    8000275c:	0000e797          	auipc	a5,0xe
    80002760:	45c78793          	addi	a5,a5,1116 # 80010bb8 <cpus+0x8>
    80002764:	9c3e                	add	s8,s8,a5
        p->state = RUNNING;
    80002766:	4c91                	li	s9,4
        c->proc = p;
    80002768:	049e                	slli	s1,s1,0x7
    8000276a:	0000eb97          	auipc	s7,0xe
    8000276e:	416b8b93          	addi	s7,s7,1046 # 80010b80 <pid_lock>
    80002772:	9ba6                	add	s7,s7,s1
      if(policy == 0)
    80002774:	00006a97          	auipc	s5,0x6
    80002778:	194a8a93          	addi	s5,s5,404 # 80008908 <policy>
    for (p = proc; p < &proc[NPROC]; p++)
    8000277c:	00015a17          	auipc	s4,0x15
    80002780:	434a0a13          	addi	s4,s4,1076 # 80017bb0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002784:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002788:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000278c:	10079073          	csrw	sstatus,a5
    80002790:	0000f497          	auipc	s1,0xf
    80002794:	82048493          	addi	s1,s1,-2016 # 80010fb0 <proc>
      if (p->state == RUNNABLE )
    80002798:	498d                	li	s3,3
      else if(policy == 1)
    8000279a:	4b05                	li	s6,1
    8000279c:	a835                	j	800027d8 <schedulerCFS+0xb8>
        virtual_time = check_vruntime(p);
    8000279e:	8526                	mv	a0,s1
    800027a0:	00000097          	auipc	ra,0x0
    800027a4:	eba080e7          	jalr	-326(ra) # 8000265a <check_vruntime>
        if (virtual_time <= minimum ){
    800027a8:	04a94063          	blt	s2,a0,800027e8 <schedulerCFS+0xc8>
        p->state = RUNNING;
    800027ac:	0194ac23          	sw	s9,24(s1)
        c->proc = p;
    800027b0:	029bb823          	sd	s1,48(s7)
        swtch(&c->context, &p->context);
    800027b4:	06048593          	addi	a1,s1,96
    800027b8:	8562                	mv	a0,s8
    800027ba:	00000097          	auipc	ra,0x0
    800027be:	36e080e7          	jalr	878(ra) # 80002b28 <swtch>
        c->proc = 0;
    800027c2:	020bb823          	sd	zero,48(s7)
    800027c6:	a00d                	j	800027e8 <schedulerCFS+0xc8>
          scheduler_old(); 
    800027c8:	00000097          	auipc	ra,0x0
    800027cc:	048080e7          	jalr	72(ra) # 80002810 <scheduler_old>
    for (p = proc; p < &proc[NPROC]; p++)
    800027d0:	1b048493          	addi	s1,s1,432
    800027d4:	fb4488e3          	beq	s1,s4,80002784 <schedulerCFS+0x64>
      acquire(&p->lock);
    800027d8:	8526                	mv	a0,s1
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	3fc080e7          	jalr	1020(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE )
    800027e2:	4c9c                	lw	a5,24(s1)
    800027e4:	fb378de3          	beq	a5,s3,8000279e <schedulerCFS+0x7e>
      release(&p->lock);
    800027e8:	8526                	mv	a0,s1
    800027ea:	ffffe097          	auipc	ra,0xffffe
    800027ee:	4a0080e7          	jalr	1184(ra) # 80000c8a <release>
      minimum = minimum_vruntime();
    800027f2:	00000097          	auipc	ra,0x0
    800027f6:	eb6080e7          	jalr	-330(ra) # 800026a8 <minimum_vruntime>
    800027fa:	892a                	mv	s2,a0
      if(policy == 0)
    800027fc:	000aa783          	lw	a5,0(s5)
    80002800:	d7e1                	beqz	a5,800027c8 <schedulerCFS+0xa8>
      else if(policy == 1)
    80002802:	fd6797e3          	bne	a5,s6,800027d0 <schedulerCFS+0xb0>
          schedulerPriority();
    80002806:	00000097          	auipc	ra,0x0
    8000280a:	0d6080e7          	jalr	214(ra) # 800028dc <schedulerPriority>
    8000280e:	b7c9                	j	800027d0 <schedulerCFS+0xb0>

0000000080002810 <scheduler_old>:
{
    80002810:	715d                	addi	sp,sp,-80
    80002812:	e486                	sd	ra,72(sp)
    80002814:	e0a2                	sd	s0,64(sp)
    80002816:	fc26                	sd	s1,56(sp)
    80002818:	f84a                	sd	s2,48(sp)
    8000281a:	f44e                	sd	s3,40(sp)
    8000281c:	f052                	sd	s4,32(sp)
    8000281e:	ec56                	sd	s5,24(sp)
    80002820:	e85a                	sd	s6,16(sp)
    80002822:	e45e                	sd	s7,8(sp)
    80002824:	e062                	sd	s8,0(sp)
    80002826:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    80002828:	8b12                	mv	s6,tp
  int id = r_tp();
    8000282a:	2b01                	sext.w	s6,s6
  c->proc = 0;
    8000282c:	007b1b93          	slli	s7,s6,0x7
    80002830:	0000e797          	auipc	a5,0xe
    80002834:	35078793          	addi	a5,a5,848 # 80010b80 <pid_lock>
    80002838:	97de                	add	a5,a5,s7
    8000283a:	0207b823          	sd	zero,48(a5)
        swtch(&c->context, &p->context);
    8000283e:	0000e797          	auipc	a5,0xe
    80002842:	37a78793          	addi	a5,a5,890 # 80010bb8 <cpus+0x8>
    80002846:	9bbe                	add	s7,s7,a5
      if(p->state == RUNNABLE) {
    80002848:	4a0d                	li	s4,3
        c->proc = p;
    8000284a:	0b1e                	slli	s6,s6,0x7
    8000284c:	0000e797          	auipc	a5,0xe
    80002850:	33478793          	addi	a5,a5,820 # 80010b80 <pid_lock>
    80002854:	9b3e                	add	s6,s6,a5
      if(policy == 1)
    80002856:	00006997          	auipc	s3,0x6
    8000285a:	0b298993          	addi	s3,s3,178 # 80008908 <policy>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000285e:	00015a97          	auipc	s5,0x15
    80002862:	352a8a93          	addi	s5,s5,850 # 80017bb0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002866:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000286a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000286e:	10079073          	csrw	sstatus,a5
    80002872:	0000e497          	auipc	s1,0xe
    80002876:	73e48493          	addi	s1,s1,1854 # 80010fb0 <proc>
        p->state = RUNNING;
    8000287a:	4c11                	li	s8,4
      if(policy == 1)
    8000287c:	4905                	li	s2,1
    8000287e:	a03d                	j	800028ac <scheduler_old+0x9c>
        p->state = RUNNING;
    80002880:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80002884:	029b3823          	sd	s1,48(s6)
        swtch(&c->context, &p->context);
    80002888:	06048593          	addi	a1,s1,96
    8000288c:	855e                	mv	a0,s7
    8000288e:	00000097          	auipc	ra,0x0
    80002892:	29a080e7          	jalr	666(ra) # 80002b28 <swtch>
        c->proc = 0;
    80002896:	020b3823          	sd	zero,48(s6)
    8000289a:	a00d                	j	800028bc <scheduler_old+0xac>
        schedulerPriority();
    8000289c:	00000097          	auipc	ra,0x0
    800028a0:	040080e7          	jalr	64(ra) # 800028dc <schedulerPriority>
    for(p = proc; p < &proc[NPROC]; p++) {
    800028a4:	1b048493          	addi	s1,s1,432
    800028a8:	fb548fe3          	beq	s1,s5,80002866 <scheduler_old+0x56>
      acquire(&p->lock);
    800028ac:	8526                	mv	a0,s1
    800028ae:	ffffe097          	auipc	ra,0xffffe
    800028b2:	328080e7          	jalr	808(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    800028b6:	4c9c                	lw	a5,24(s1)
    800028b8:	fd4784e3          	beq	a5,s4,80002880 <scheduler_old+0x70>
      release(&p->lock);
    800028bc:	8526                	mv	a0,s1
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	3cc080e7          	jalr	972(ra) # 80000c8a <release>
      if(policy == 1)
    800028c6:	0009a783          	lw	a5,0(s3)
    800028ca:	fd2789e3          	beq	a5,s2,8000289c <scheduler_old+0x8c>
      else if(policy == 2)
    800028ce:	4709                	li	a4,2
    800028d0:	fce79ae3          	bne	a5,a4,800028a4 <scheduler_old+0x94>
        schedulerCFS();
    800028d4:	00000097          	auipc	ra,0x0
    800028d8:	e4c080e7          	jalr	-436(ra) # 80002720 <schedulerCFS>

00000000800028dc <schedulerPriority>:
{
    800028dc:	711d                	addi	sp,sp,-96
    800028de:	ec86                	sd	ra,88(sp)
    800028e0:	e8a2                	sd	s0,80(sp)
    800028e2:	e4a6                	sd	s1,72(sp)
    800028e4:	e0ca                	sd	s2,64(sp)
    800028e6:	fc4e                	sd	s3,56(sp)
    800028e8:	f852                	sd	s4,48(sp)
    800028ea:	f456                	sd	s5,40(sp)
    800028ec:	f05a                	sd	s6,32(sp)
    800028ee:	ec5e                	sd	s7,24(sp)
    800028f0:	e862                	sd	s8,16(sp)
    800028f2:	e466                	sd	s9,8(sp)
    800028f4:	e06a                	sd	s10,0(sp)
    800028f6:	1080                	addi	s0,sp,96
  asm volatile("mv %0, tp" : "=r" (x) );
    800028f8:	8492                	mv	s1,tp
  int id = r_tp();
    800028fa:	2481                	sext.w	s1,s1
  long long minimum = find_minimum();
    800028fc:	fffff097          	auipc	ra,0xfffff
    80002900:	5e4080e7          	jalr	1508(ra) # 80001ee0 <find_minimum>
    80002904:	892a                	mv	s2,a0
  c->proc = 0;
    80002906:	00749993          	slli	s3,s1,0x7
    8000290a:	0000e797          	auipc	a5,0xe
    8000290e:	27678793          	addi	a5,a5,630 # 80010b80 <pid_lock>
    80002912:	97ce                	add	a5,a5,s3
    80002914:	0207b823          	sd	zero,48(a5)
        swtch(&c->context, &p->context);
    80002918:	0000e797          	auipc	a5,0xe
    8000291c:	2a078793          	addi	a5,a5,672 # 80010bb8 <cpus+0x8>
    80002920:	99be                	add	s3,s3,a5
      if (p->state == RUNNABLE )
    80002922:	4a8d                	li	s5,3
        c->proc = p;
    80002924:	049e                	slli	s1,s1,0x7
    80002926:	0000eb17          	auipc	s6,0xe
    8000292a:	25ab0b13          	addi	s6,s6,602 # 80010b80 <pid_lock>
    8000292e:	9b26                	add	s6,s6,s1
      if(policy == 0)
    80002930:	00006a17          	auipc	s4,0x6
    80002934:	fd8a0a13          	addi	s4,s4,-40 # 80008908 <policy>
    for (p = proc; p < &proc[NPROC]; p++)
    80002938:	00015c17          	auipc	s8,0x15
    8000293c:	278c0c13          	addi	s8,s8,632 # 80017bb0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002940:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002944:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002948:	10079073          	csrw	sstatus,a5
    8000294c:	0000e497          	auipc	s1,0xe
    80002950:	66448493          	addi	s1,s1,1636 # 80010fb0 <proc>
        p->state = RUNNING;
    80002954:	4c91                	li	s9,4
      else if(policy == 2)
    80002956:	4b89                	li	s7,2
      acquire(&p->lock);
    80002958:	8526                	mv	a0,s1
    8000295a:	ffffe097          	auipc	ra,0xffffe
    8000295e:	27c080e7          	jalr	636(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE )
    80002962:	4c9c                	lw	a5,24(s1)
    80002964:	03578663          	beq	a5,s5,80002990 <schedulerPriority+0xb4>
      release(&p->lock);
    80002968:	8526                	mv	a0,s1
    8000296a:	ffffe097          	auipc	ra,0xffffe
    8000296e:	320080e7          	jalr	800(ra) # 80000c8a <release>
      minimum = find_minimum();
    80002972:	fffff097          	auipc	ra,0xfffff
    80002976:	56e080e7          	jalr	1390(ra) # 80001ee0 <find_minimum>
    8000297a:	892a                	mv	s2,a0
      if(policy == 0)
    8000297c:	000a2783          	lw	a5,0(s4)
    80002980:	cb95                	beqz	a5,800029b4 <schedulerPriority+0xd8>
      else if(policy == 2)
    80002982:	03778d63          	beq	a5,s7,800029bc <schedulerPriority+0xe0>
    for (p = proc; p < &proc[NPROC]; p++)
    80002986:	1b048493          	addi	s1,s1,432
    8000298a:	fd8497e3          	bne	s1,s8,80002958 <schedulerPriority+0x7c>
    8000298e:	bf4d                	j	80002940 <schedulerPriority+0x64>
        if (p -> accumulator <= minimum ){
    80002990:	1884b783          	ld	a5,392(s1)
    80002994:	fcf94ae3          	blt	s2,a5,80002968 <schedulerPriority+0x8c>
        p->state = RUNNING;
    80002998:	0194ac23          	sw	s9,24(s1)
        c->proc = p;
    8000299c:	029b3823          	sd	s1,48(s6)
        swtch(&c->context, &p->context);
    800029a0:	06048593          	addi	a1,s1,96
    800029a4:	854e                	mv	a0,s3
    800029a6:	00000097          	auipc	ra,0x0
    800029aa:	182080e7          	jalr	386(ra) # 80002b28 <swtch>
        c->proc = 0;
    800029ae:	020b3823          	sd	zero,48(s6)
    800029b2:	bf5d                	j	80002968 <schedulerPriority+0x8c>
        scheduler_old(); 
    800029b4:	00000097          	auipc	ra,0x0
    800029b8:	e5c080e7          	jalr	-420(ra) # 80002810 <scheduler_old>
        schedulerCFS();
    800029bc:	00000097          	auipc	ra,0x0
    800029c0:	d64080e7          	jalr	-668(ra) # 80002720 <schedulerCFS>

00000000800029c4 <scheduler>:
scheduler(void){
    800029c4:	1141                	addi	sp,sp,-16
    800029c6:	e406                	sd	ra,8(sp)
    800029c8:	e022                	sd	s0,0(sp)
    800029ca:	0800                	addi	s0,sp,16
  if(policy == 0)
    800029cc:	00006797          	auipc	a5,0x6
    800029d0:	f3c7a783          	lw	a5,-196(a5) # 80008908 <policy>
    800029d4:	cb99                	beqz	a5,800029ea <scheduler+0x26>
  else if(policy == 1)
    800029d6:	4705                	li	a4,1
    800029d8:	00e78d63          	beq	a5,a4,800029f2 <scheduler+0x2e>
  else if(policy == 2)
    800029dc:	4709                	li	a4,2
    800029de:	00e78e63          	beq	a5,a4,800029fa <scheduler+0x36>
}
    800029e2:	60a2                	ld	ra,8(sp)
    800029e4:	6402                	ld	s0,0(sp)
    800029e6:	0141                	addi	sp,sp,16
    800029e8:	8082                	ret
      scheduler_old();
    800029ea:	00000097          	auipc	ra,0x0
    800029ee:	e26080e7          	jalr	-474(ra) # 80002810 <scheduler_old>
      schedulerPriority();
    800029f2:	00000097          	auipc	ra,0x0
    800029f6:	eea080e7          	jalr	-278(ra) # 800028dc <schedulerPriority>
      schedulerCFS();
    800029fa:	00000097          	auipc	ra,0x0
    800029fe:	d26080e7          	jalr	-730(ra) # 80002720 <schedulerCFS>

0000000080002a02 <set_cfs_priority>:

void set_cfs_priority(int priority)
{
    80002a02:	1101                	addi	sp,sp,-32
    80002a04:	ec06                	sd	ra,24(sp)
    80002a06:	e822                	sd	s0,16(sp)
    80002a08:	e426                	sd	s1,8(sp)
    80002a0a:	1000                	addi	s0,sp,32
    80002a0c:	84aa                	mv	s1,a0
  myproc() -> cfs_priority = priority; 
    80002a0e:	fffff097          	auipc	ra,0xfffff
    80002a12:	fa6080e7          	jalr	-90(ra) # 800019b4 <myproc>
    80002a16:	18952a23          	sw	s1,404(a0)
  return; 
}
    80002a1a:	60e2                	ld	ra,24(sp)
    80002a1c:	6442                	ld	s0,16(sp)
    80002a1e:	64a2                	ld	s1,8(sp)
    80002a20:	6105                	addi	sp,sp,32
    80002a22:	8082                	ret

0000000080002a24 <get_cfs_priority>:
int get_cfs_priority(int pid, uint64 dst)
{
  struct proc *pp;

  struct proc_info info;
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002a24:	0000e797          	auipc	a5,0xe
    80002a28:	58c78793          	addi	a5,a5,1420 # 80010fb0 <proc>
    80002a2c:	00015697          	auipc	a3,0x15
    80002a30:	18468693          	addi	a3,a3,388 # 80017bb0 <tickslock>
  {
    if (pp -> pid == pid )
    80002a34:	5b98                	lw	a4,48(a5)
    80002a36:	00a70863          	beq	a4,a0,80002a46 <get_cfs_priority+0x22>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002a3a:	1b078793          	addi	a5,a5,432
    80002a3e:	fed79be3          	bne	a5,a3,80002a34 <get_cfs_priority+0x10>
        return -1; 
      }
      return 0; 
    }
  }
  return -1; 
    80002a42:	557d                	li	a0,-1
}
    80002a44:	8082                	ret
{
    80002a46:	1101                	addi	sp,sp,-32
    80002a48:	ec06                	sd	ra,24(sp)
    80002a4a:	e822                	sd	s0,16(sp)
    80002a4c:	1000                	addi	s0,sp,32
      info.cfs_priority = pp -> cfs_priority;
    80002a4e:	1947a703          	lw	a4,404(a5)
    80002a52:	fee42023          	sw	a4,-32(s0)
      info.retime = pp -> retime;
    80002a56:	1a87b703          	ld	a4,424(a5)
    80002a5a:	fee42223          	sw	a4,-28(s0)
      info.rtime = pp -> rtime; 
    80002a5e:	1987b703          	ld	a4,408(a5)
    80002a62:	fee42423          	sw	a4,-24(s0)
      info.stime = pp -> stime;  
    80002a66:	1a07b703          	ld	a4,416(a5)
    80002a6a:	fee42623          	sw	a4,-20(s0)
      if(copyout(pp->pagetable, dst, (char*) &info, sizeof(struct proc_info)) < 0 )
    80002a6e:	46c1                	li	a3,16
    80002a70:	fe040613          	addi	a2,s0,-32
    80002a74:	6ba8                	ld	a0,80(a5)
    80002a76:	fffff097          	auipc	ra,0xfffff
    80002a7a:	bfa080e7          	jalr	-1030(ra) # 80001670 <copyout>
    80002a7e:	41f5551b          	sraiw	a0,a0,0x1f
}
    80002a82:	60e2                	ld	ra,24(sp)
    80002a84:	6442                	ld	s0,16(sp)
    80002a86:	6105                	addi	sp,sp,32
    80002a88:	8082                	ret

0000000080002a8a <update_ticks>:

void update_ticks()
{
    80002a8a:	7139                	addi	sp,sp,-64
    80002a8c:	fc06                	sd	ra,56(sp)
    80002a8e:	f822                	sd	s0,48(sp)
    80002a90:	f426                	sd	s1,40(sp)
    80002a92:	f04a                	sd	s2,32(sp)
    80002a94:	ec4e                	sd	s3,24(sp)
    80002a96:	e852                	sd	s4,16(sp)
    80002a98:	e456                	sd	s5,8(sp)
    80002a9a:	0080                	addi	s0,sp,64
  struct proc *p;
    for (p = proc; p < &proc[NPROC]; p++)
    80002a9c:	0000e497          	auipc	s1,0xe
    80002aa0:	51448493          	addi	s1,s1,1300 # 80010fb0 <proc>
  {
      if (p -> state == SLEEPING){
    80002aa4:	4a09                	li	s4,2
      p -> stime = p -> stime +1;
      }
      acquire(&p->lock);
      if (p -> state == RUNNABLE){
    80002aa6:	498d                	li	s3,3
        p -> retime  = p -> retime +1;
      }
      if (p-> state == RUNNING){
    80002aa8:	4a91                	li	s5,4
    for (p = proc; p < &proc[NPROC]; p++)
    80002aaa:	00015917          	auipc	s2,0x15
    80002aae:	10690913          	addi	s2,s2,262 # 80017bb0 <tickslock>
    80002ab2:	a02d                	j	80002adc <update_ticks+0x52>
      p -> stime = p -> stime +1;
    80002ab4:	1a04b783          	ld	a5,416(s1)
    80002ab8:	0785                	addi	a5,a5,1
    80002aba:	1af4b023          	sd	a5,416(s1)
    80002abe:	a015                	j	80002ae2 <update_ticks+0x58>
        p -> retime  = p -> retime +1;
    80002ac0:	1a84b783          	ld	a5,424(s1)
    80002ac4:	0785                	addi	a5,a5,1
    80002ac6:	1af4b423          	sd	a5,424(s1)
        p -> rtime = p -> rtime +1; 
      }

      //printf("%s\n",p -> state, 5);
      release(&p ->lock);
    80002aca:	8526                	mv	a0,s1
    80002acc:	ffffe097          	auipc	ra,0xffffe
    80002ad0:	1be080e7          	jalr	446(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002ad4:	1b048493          	addi	s1,s1,432
    80002ad8:	03248563          	beq	s1,s2,80002b02 <update_ticks+0x78>
      if (p -> state == SLEEPING){
    80002adc:	4c9c                	lw	a5,24(s1)
    80002ade:	fd478be3          	beq	a5,s4,80002ab4 <update_ticks+0x2a>
      acquire(&p->lock);
    80002ae2:	8526                	mv	a0,s1
    80002ae4:	ffffe097          	auipc	ra,0xffffe
    80002ae8:	0f2080e7          	jalr	242(ra) # 80000bd6 <acquire>
      if (p -> state == RUNNABLE){
    80002aec:	4c9c                	lw	a5,24(s1)
    80002aee:	fd3789e3          	beq	a5,s3,80002ac0 <update_ticks+0x36>
      if (p-> state == RUNNING){
    80002af2:	fd579ce3          	bne	a5,s5,80002aca <update_ticks+0x40>
        p -> rtime = p -> rtime +1; 
    80002af6:	1984b783          	ld	a5,408(s1)
    80002afa:	0785                	addi	a5,a5,1
    80002afc:	18f4bc23          	sd	a5,408(s1)
    80002b00:	b7e9                	j	80002aca <update_ticks+0x40>
  }
}
    80002b02:	70e2                	ld	ra,56(sp)
    80002b04:	7442                	ld	s0,48(sp)
    80002b06:	74a2                	ld	s1,40(sp)
    80002b08:	7902                	ld	s2,32(sp)
    80002b0a:	69e2                	ld	s3,24(sp)
    80002b0c:	6a42                	ld	s4,16(sp)
    80002b0e:	6aa2                	ld	s5,8(sp)
    80002b10:	6121                	addi	sp,sp,64
    80002b12:	8082                	ret

0000000080002b14 <set_policy>:

void 
set_policy(int new_policy){
    80002b14:	1141                	addi	sp,sp,-16
    80002b16:	e422                	sd	s0,8(sp)
    80002b18:	0800                	addi	s0,sp,16
  policy = new_policy;
    80002b1a:	00006797          	auipc	a5,0x6
    80002b1e:	dea7a723          	sw	a0,-530(a5) # 80008908 <policy>
  return;
    80002b22:	6422                	ld	s0,8(sp)
    80002b24:	0141                	addi	sp,sp,16
    80002b26:	8082                	ret

0000000080002b28 <swtch>:
    80002b28:	00153023          	sd	ra,0(a0)
    80002b2c:	00253423          	sd	sp,8(a0)
    80002b30:	e900                	sd	s0,16(a0)
    80002b32:	ed04                	sd	s1,24(a0)
    80002b34:	03253023          	sd	s2,32(a0)
    80002b38:	03353423          	sd	s3,40(a0)
    80002b3c:	03453823          	sd	s4,48(a0)
    80002b40:	03553c23          	sd	s5,56(a0)
    80002b44:	05653023          	sd	s6,64(a0)
    80002b48:	05753423          	sd	s7,72(a0)
    80002b4c:	05853823          	sd	s8,80(a0)
    80002b50:	05953c23          	sd	s9,88(a0)
    80002b54:	07a53023          	sd	s10,96(a0)
    80002b58:	07b53423          	sd	s11,104(a0)
    80002b5c:	0005b083          	ld	ra,0(a1)
    80002b60:	0085b103          	ld	sp,8(a1)
    80002b64:	6980                	ld	s0,16(a1)
    80002b66:	6d84                	ld	s1,24(a1)
    80002b68:	0205b903          	ld	s2,32(a1)
    80002b6c:	0285b983          	ld	s3,40(a1)
    80002b70:	0305ba03          	ld	s4,48(a1)
    80002b74:	0385ba83          	ld	s5,56(a1)
    80002b78:	0405bb03          	ld	s6,64(a1)
    80002b7c:	0485bb83          	ld	s7,72(a1)
    80002b80:	0505bc03          	ld	s8,80(a1)
    80002b84:	0585bc83          	ld	s9,88(a1)
    80002b88:	0605bd03          	ld	s10,96(a1)
    80002b8c:	0685bd83          	ld	s11,104(a1)
    80002b90:	8082                	ret

0000000080002b92 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002b92:	1141                	addi	sp,sp,-16
    80002b94:	e406                	sd	ra,8(sp)
    80002b96:	e022                	sd	s0,0(sp)
    80002b98:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b9a:	00005597          	auipc	a1,0x5
    80002b9e:	75e58593          	addi	a1,a1,1886 # 800082f8 <states.0+0x30>
    80002ba2:	00015517          	auipc	a0,0x15
    80002ba6:	00e50513          	addi	a0,a0,14 # 80017bb0 <tickslock>
    80002baa:	ffffe097          	auipc	ra,0xffffe
    80002bae:	f9c080e7          	jalr	-100(ra) # 80000b46 <initlock>
}
    80002bb2:	60a2                	ld	ra,8(sp)
    80002bb4:	6402                	ld	s0,0(sp)
    80002bb6:	0141                	addi	sp,sp,16
    80002bb8:	8082                	ret

0000000080002bba <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002bba:	1141                	addi	sp,sp,-16
    80002bbc:	e422                	sd	s0,8(sp)
    80002bbe:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bc0:	00003797          	auipc	a5,0x3
    80002bc4:	63078793          	addi	a5,a5,1584 # 800061f0 <kernelvec>
    80002bc8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002bcc:	6422                	ld	s0,8(sp)
    80002bce:	0141                	addi	sp,sp,16
    80002bd0:	8082                	ret

0000000080002bd2 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002bd2:	1141                	addi	sp,sp,-16
    80002bd4:	e406                	sd	ra,8(sp)
    80002bd6:	e022                	sd	s0,0(sp)
    80002bd8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002bda:	fffff097          	auipc	ra,0xfffff
    80002bde:	dda080e7          	jalr	-550(ra) # 800019b4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002be2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002be6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002be8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002bec:	00004617          	auipc	a2,0x4
    80002bf0:	41460613          	addi	a2,a2,1044 # 80007000 <_trampoline>
    80002bf4:	00004697          	auipc	a3,0x4
    80002bf8:	40c68693          	addi	a3,a3,1036 # 80007000 <_trampoline>
    80002bfc:	8e91                	sub	a3,a3,a2
    80002bfe:	040007b7          	lui	a5,0x4000
    80002c02:	17fd                	addi	a5,a5,-1
    80002c04:	07b2                	slli	a5,a5,0xc
    80002c06:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c08:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c0c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c0e:	180026f3          	csrr	a3,satp
    80002c12:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c14:	6d38                	ld	a4,88(a0)
    80002c16:	6134                	ld	a3,64(a0)
    80002c18:	6585                	lui	a1,0x1
    80002c1a:	96ae                	add	a3,a3,a1
    80002c1c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c1e:	6d38                	ld	a4,88(a0)
    80002c20:	00000697          	auipc	a3,0x0
    80002c24:	13068693          	addi	a3,a3,304 # 80002d50 <usertrap>
    80002c28:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002c2a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c2c:	8692                	mv	a3,tp
    80002c2e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c30:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c34:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c38:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c3c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c40:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c42:	6f18                	ld	a4,24(a4)
    80002c44:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c48:	6928                	ld	a0,80(a0)
    80002c4a:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002c4c:	00004717          	auipc	a4,0x4
    80002c50:	45070713          	addi	a4,a4,1104 # 8000709c <userret>
    80002c54:	8f11                	sub	a4,a4,a2
    80002c56:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002c58:	577d                	li	a4,-1
    80002c5a:	177e                	slli	a4,a4,0x3f
    80002c5c:	8d59                	or	a0,a0,a4
    80002c5e:	9782                	jalr	a5
}
    80002c60:	60a2                	ld	ra,8(sp)
    80002c62:	6402                	ld	s0,0(sp)
    80002c64:	0141                	addi	sp,sp,16
    80002c66:	8082                	ret

0000000080002c68 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002c68:	1101                	addi	sp,sp,-32
    80002c6a:	ec06                	sd	ra,24(sp)
    80002c6c:	e822                	sd	s0,16(sp)
    80002c6e:	e426                	sd	s1,8(sp)
    80002c70:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c72:	00015497          	auipc	s1,0x15
    80002c76:	f3e48493          	addi	s1,s1,-194 # 80017bb0 <tickslock>
    80002c7a:	8526                	mv	a0,s1
    80002c7c:	ffffe097          	auipc	ra,0xffffe
    80002c80:	f5a080e7          	jalr	-166(ra) # 80000bd6 <acquire>
  ticks++;
    80002c84:	00006517          	auipc	a0,0x6
    80002c88:	c9450513          	addi	a0,a0,-876 # 80008918 <ticks>
    80002c8c:	411c                	lw	a5,0(a0)
    80002c8e:	2785                	addiw	a5,a5,1
    80002c90:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002c92:	fffff097          	auipc	ra,0xfffff
    80002c96:	436080e7          	jalr	1078(ra) # 800020c8 <wakeup>
  release(&tickslock);
    80002c9a:	8526                	mv	a0,s1
    80002c9c:	ffffe097          	auipc	ra,0xffffe
    80002ca0:	fee080e7          	jalr	-18(ra) # 80000c8a <release>
}
    80002ca4:	60e2                	ld	ra,24(sp)
    80002ca6:	6442                	ld	s0,16(sp)
    80002ca8:	64a2                	ld	s1,8(sp)
    80002caa:	6105                	addi	sp,sp,32
    80002cac:	8082                	ret

0000000080002cae <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002cae:	1101                	addi	sp,sp,-32
    80002cb0:	ec06                	sd	ra,24(sp)
    80002cb2:	e822                	sd	s0,16(sp)
    80002cb4:	e426                	sd	s1,8(sp)
    80002cb6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cb8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002cbc:	00074d63          	bltz	a4,80002cd6 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002cc0:	57fd                	li	a5,-1
    80002cc2:	17fe                	slli	a5,a5,0x3f
    80002cc4:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002cc6:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002cc8:	06f70363          	beq	a4,a5,80002d2e <devintr+0x80>
  }
}
    80002ccc:	60e2                	ld	ra,24(sp)
    80002cce:	6442                	ld	s0,16(sp)
    80002cd0:	64a2                	ld	s1,8(sp)
    80002cd2:	6105                	addi	sp,sp,32
    80002cd4:	8082                	ret
      (scause & 0xff) == 9)
    80002cd6:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002cda:	46a5                	li	a3,9
    80002cdc:	fed792e3          	bne	a5,a3,80002cc0 <devintr+0x12>
    int irq = plic_claim();
    80002ce0:	00003097          	auipc	ra,0x3
    80002ce4:	618080e7          	jalr	1560(ra) # 800062f8 <plic_claim>
    80002ce8:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002cea:	47a9                	li	a5,10
    80002cec:	02f50763          	beq	a0,a5,80002d1a <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002cf0:	4785                	li	a5,1
    80002cf2:	02f50963          	beq	a0,a5,80002d24 <devintr+0x76>
    return 1;
    80002cf6:	4505                	li	a0,1
    else if (irq)
    80002cf8:	d8f1                	beqz	s1,80002ccc <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002cfa:	85a6                	mv	a1,s1
    80002cfc:	00005517          	auipc	a0,0x5
    80002d00:	60450513          	addi	a0,a0,1540 # 80008300 <states.0+0x38>
    80002d04:	ffffe097          	auipc	ra,0xffffe
    80002d08:	884080e7          	jalr	-1916(ra) # 80000588 <printf>
      plic_complete(irq);
    80002d0c:	8526                	mv	a0,s1
    80002d0e:	00003097          	auipc	ra,0x3
    80002d12:	60e080e7          	jalr	1550(ra) # 8000631c <plic_complete>
    return 1;
    80002d16:	4505                	li	a0,1
    80002d18:	bf55                	j	80002ccc <devintr+0x1e>
      uartintr();
    80002d1a:	ffffe097          	auipc	ra,0xffffe
    80002d1e:	c80080e7          	jalr	-896(ra) # 8000099a <uartintr>
    80002d22:	b7ed                	j	80002d0c <devintr+0x5e>
      virtio_disk_intr();
    80002d24:	00004097          	auipc	ra,0x4
    80002d28:	ac4080e7          	jalr	-1340(ra) # 800067e8 <virtio_disk_intr>
    80002d2c:	b7c5                	j	80002d0c <devintr+0x5e>
    if (cpuid() == 0)
    80002d2e:	fffff097          	auipc	ra,0xfffff
    80002d32:	c5a080e7          	jalr	-934(ra) # 80001988 <cpuid>
    80002d36:	c901                	beqz	a0,80002d46 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d38:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d3c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d3e:	14479073          	csrw	sip,a5
    return 2;
    80002d42:	4509                	li	a0,2
    80002d44:	b761                	j	80002ccc <devintr+0x1e>
      clockintr();
    80002d46:	00000097          	auipc	ra,0x0
    80002d4a:	f22080e7          	jalr	-222(ra) # 80002c68 <clockintr>
    80002d4e:	b7ed                	j	80002d38 <devintr+0x8a>

0000000080002d50 <usertrap>:
{
    80002d50:	1101                	addi	sp,sp,-32
    80002d52:	ec06                	sd	ra,24(sp)
    80002d54:	e822                	sd	s0,16(sp)
    80002d56:	e426                	sd	s1,8(sp)
    80002d58:	e04a                	sd	s2,0(sp)
    80002d5a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d5c:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002d60:	1007f793          	andi	a5,a5,256
    80002d64:	e3b1                	bnez	a5,80002da8 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d66:	00003797          	auipc	a5,0x3
    80002d6a:	48a78793          	addi	a5,a5,1162 # 800061f0 <kernelvec>
    80002d6e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d72:	fffff097          	auipc	ra,0xfffff
    80002d76:	c42080e7          	jalr	-958(ra) # 800019b4 <myproc>
    80002d7a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d7c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d7e:	14102773          	csrr	a4,sepc
    80002d82:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d84:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002d88:	47a1                	li	a5,8
    80002d8a:	02f70763          	beq	a4,a5,80002db8 <usertrap+0x68>
  else if ((which_dev = devintr()) != 0)
    80002d8e:	00000097          	auipc	ra,0x0
    80002d92:	f20080e7          	jalr	-224(ra) # 80002cae <devintr>
    80002d96:	892a                	mv	s2,a0
    80002d98:	c951                	beqz	a0,80002e2c <usertrap+0xdc>
  if (killed(p))
    80002d9a:	8526                	mv	a0,s1
    80002d9c:	fffff097          	auipc	ra,0xfffff
    80002da0:	582080e7          	jalr	1410(ra) # 8000231e <killed>
    80002da4:	cd29                	beqz	a0,80002dfe <usertrap+0xae>
    80002da6:	a099                	j	80002dec <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002da8:	00005517          	auipc	a0,0x5
    80002dac:	57850513          	addi	a0,a0,1400 # 80008320 <states.0+0x58>
    80002db0:	ffffd097          	auipc	ra,0xffffd
    80002db4:	78e080e7          	jalr	1934(ra) # 8000053e <panic>
    if (killed(p))
    80002db8:	fffff097          	auipc	ra,0xfffff
    80002dbc:	566080e7          	jalr	1382(ra) # 8000231e <killed>
    80002dc0:	ed21                	bnez	a0,80002e18 <usertrap+0xc8>
    p->trapframe->epc += 4;
    80002dc2:	6cb8                	ld	a4,88(s1)
    80002dc4:	6f1c                	ld	a5,24(a4)
    80002dc6:	0791                	addi	a5,a5,4
    80002dc8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dca:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002dce:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dd2:	10079073          	csrw	sstatus,a5
    syscall();
    80002dd6:	00000097          	auipc	ra,0x0
    80002dda:	32c080e7          	jalr	812(ra) # 80003102 <syscall>
  if (killed(p))
    80002dde:	8526                	mv	a0,s1
    80002de0:	fffff097          	auipc	ra,0xfffff
    80002de4:	53e080e7          	jalr	1342(ra) # 8000231e <killed>
    80002de8:	cd11                	beqz	a0,80002e04 <usertrap+0xb4>
    80002dea:	4901                	li	s2,0
    exit(-1, "");
    80002dec:	00005597          	auipc	a1,0x5
    80002df0:	57c58593          	addi	a1,a1,1404 # 80008368 <states.0+0xa0>
    80002df4:	557d                	li	a0,-1
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	3a2080e7          	jalr	930(ra) # 80002198 <exit>
  if (which_dev == 2){
    80002dfe:	4789                	li	a5,2
    80002e00:	06f90363          	beq	s2,a5,80002e66 <usertrap+0x116>
  usertrapret();
    80002e04:	00000097          	auipc	ra,0x0
    80002e08:	dce080e7          	jalr	-562(ra) # 80002bd2 <usertrapret>
}
    80002e0c:	60e2                	ld	ra,24(sp)
    80002e0e:	6442                	ld	s0,16(sp)
    80002e10:	64a2                	ld	s1,8(sp)
    80002e12:	6902                	ld	s2,0(sp)
    80002e14:	6105                	addi	sp,sp,32
    80002e16:	8082                	ret
      exit(-1, "");
    80002e18:	00005597          	auipc	a1,0x5
    80002e1c:	55058593          	addi	a1,a1,1360 # 80008368 <states.0+0xa0>
    80002e20:	557d                	li	a0,-1
    80002e22:	fffff097          	auipc	ra,0xfffff
    80002e26:	376080e7          	jalr	886(ra) # 80002198 <exit>
    80002e2a:	bf61                	j	80002dc2 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e2c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e30:	5890                	lw	a2,48(s1)
    80002e32:	00005517          	auipc	a0,0x5
    80002e36:	50e50513          	addi	a0,a0,1294 # 80008340 <states.0+0x78>
    80002e3a:	ffffd097          	auipc	ra,0xffffd
    80002e3e:	74e080e7          	jalr	1870(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e42:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e46:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e4a:	00005517          	auipc	a0,0x5
    80002e4e:	52650513          	addi	a0,a0,1318 # 80008370 <states.0+0xa8>
    80002e52:	ffffd097          	auipc	ra,0xffffd
    80002e56:	736080e7          	jalr	1846(ra) # 80000588 <printf>
    setkilled(p);
    80002e5a:	8526                	mv	a0,s1
    80002e5c:	fffff097          	auipc	ra,0xfffff
    80002e60:	496080e7          	jalr	1174(ra) # 800022f2 <setkilled>
    80002e64:	bfad                	j	80002dde <usertrap+0x8e>
    update_ticks(); 
    80002e66:	00000097          	auipc	ra,0x0
    80002e6a:	c24080e7          	jalr	-988(ra) # 80002a8a <update_ticks>
    acquire(&p ->lock);
    80002e6e:	8526                	mv	a0,s1
    80002e70:	ffffe097          	auipc	ra,0xffffe
    80002e74:	d66080e7          	jalr	-666(ra) # 80000bd6 <acquire>
    p -> accumulator = p -> accumulator + p-> ps_priority;
    80002e78:	1904a703          	lw	a4,400(s1)
    80002e7c:	1884b783          	ld	a5,392(s1)
    80002e80:	97ba                	add	a5,a5,a4
    80002e82:	18f4b423          	sd	a5,392(s1)
    release(&p ->lock); 
    80002e86:	8526                	mv	a0,s1
    80002e88:	ffffe097          	auipc	ra,0xffffe
    80002e8c:	e02080e7          	jalr	-510(ra) # 80000c8a <release>
    yield();
    80002e90:	fffff097          	auipc	ra,0xfffff
    80002e94:	198080e7          	jalr	408(ra) # 80002028 <yield>
    80002e98:	b7b5                	j	80002e04 <usertrap+0xb4>

0000000080002e9a <kerneltrap>:
{
    80002e9a:	7179                	addi	sp,sp,-48
    80002e9c:	f406                	sd	ra,40(sp)
    80002e9e:	f022                	sd	s0,32(sp)
    80002ea0:	ec26                	sd	s1,24(sp)
    80002ea2:	e84a                	sd	s2,16(sp)
    80002ea4:	e44e                	sd	s3,8(sp)
    80002ea6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ea8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002eac:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eb0:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002eb4:	1004f793          	andi	a5,s1,256
    80002eb8:	cb85                	beqz	a5,80002ee8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002eba:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ebe:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002ec0:	ef85                	bnez	a5,80002ef8 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002ec2:	00000097          	auipc	ra,0x0
    80002ec6:	dec080e7          	jalr	-532(ra) # 80002cae <devintr>
    80002eca:	cd1d                	beqz	a0,80002f08 <kerneltrap+0x6e>
    if(which_dev == 2){
    80002ecc:	4789                	li	a5,2
    80002ece:	06f50a63          	beq	a0,a5,80002f42 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ed2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ed6:	10049073          	csrw	sstatus,s1
}
    80002eda:	70a2                	ld	ra,40(sp)
    80002edc:	7402                	ld	s0,32(sp)
    80002ede:	64e2                	ld	s1,24(sp)
    80002ee0:	6942                	ld	s2,16(sp)
    80002ee2:	69a2                	ld	s3,8(sp)
    80002ee4:	6145                	addi	sp,sp,48
    80002ee6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ee8:	00005517          	auipc	a0,0x5
    80002eec:	4a850513          	addi	a0,a0,1192 # 80008390 <states.0+0xc8>
    80002ef0:	ffffd097          	auipc	ra,0xffffd
    80002ef4:	64e080e7          	jalr	1614(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002ef8:	00005517          	auipc	a0,0x5
    80002efc:	4c050513          	addi	a0,a0,1216 # 800083b8 <states.0+0xf0>
    80002f00:	ffffd097          	auipc	ra,0xffffd
    80002f04:	63e080e7          	jalr	1598(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002f08:	85ce                	mv	a1,s3
    80002f0a:	00005517          	auipc	a0,0x5
    80002f0e:	4ce50513          	addi	a0,a0,1230 # 800083d8 <states.0+0x110>
    80002f12:	ffffd097          	auipc	ra,0xffffd
    80002f16:	676080e7          	jalr	1654(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f1a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f1e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f22:	00005517          	auipc	a0,0x5
    80002f26:	4c650513          	addi	a0,a0,1222 # 800083e8 <states.0+0x120>
    80002f2a:	ffffd097          	auipc	ra,0xffffd
    80002f2e:	65e080e7          	jalr	1630(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002f32:	00005517          	auipc	a0,0x5
    80002f36:	4ce50513          	addi	a0,a0,1230 # 80008400 <states.0+0x138>
    80002f3a:	ffffd097          	auipc	ra,0xffffd
    80002f3e:	604080e7          	jalr	1540(ra) # 8000053e <panic>
    update_ticks();
    80002f42:	00000097          	auipc	ra,0x0
    80002f46:	b48080e7          	jalr	-1208(ra) # 80002a8a <update_ticks>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002f4a:	fffff097          	auipc	ra,0xfffff
    80002f4e:	a6a080e7          	jalr	-1430(ra) # 800019b4 <myproc>
    80002f52:	d141                	beqz	a0,80002ed2 <kerneltrap+0x38>
    80002f54:	fffff097          	auipc	ra,0xfffff
    80002f58:	a60080e7          	jalr	-1440(ra) # 800019b4 <myproc>
    80002f5c:	4d18                	lw	a4,24(a0)
    80002f5e:	4791                	li	a5,4
    80002f60:	f6f719e3          	bne	a4,a5,80002ed2 <kerneltrap+0x38>
    struct proc *p = myproc();
    80002f64:	fffff097          	auipc	ra,0xfffff
    80002f68:	a50080e7          	jalr	-1456(ra) # 800019b4 <myproc>
    p -> accumulator = p -> accumulator + p-> ps_priority;
    80002f6c:	19052703          	lw	a4,400(a0)
    80002f70:	18853783          	ld	a5,392(a0)
    80002f74:	97ba                	add	a5,a5,a4
    80002f76:	18f53423          	sd	a5,392(a0)
    yield();
    80002f7a:	fffff097          	auipc	ra,0xfffff
    80002f7e:	0ae080e7          	jalr	174(ra) # 80002028 <yield>
    80002f82:	bf81                	j	80002ed2 <kerneltrap+0x38>

0000000080002f84 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f84:	1101                	addi	sp,sp,-32
    80002f86:	ec06                	sd	ra,24(sp)
    80002f88:	e822                	sd	s0,16(sp)
    80002f8a:	e426                	sd	s1,8(sp)
    80002f8c:	1000                	addi	s0,sp,32
    80002f8e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f90:	fffff097          	auipc	ra,0xfffff
    80002f94:	a24080e7          	jalr	-1500(ra) # 800019b4 <myproc>
  switch (n) {
    80002f98:	4795                	li	a5,5
    80002f9a:	0497e163          	bltu	a5,s1,80002fdc <argraw+0x58>
    80002f9e:	048a                	slli	s1,s1,0x2
    80002fa0:	00005717          	auipc	a4,0x5
    80002fa4:	49870713          	addi	a4,a4,1176 # 80008438 <states.0+0x170>
    80002fa8:	94ba                	add	s1,s1,a4
    80002faa:	409c                	lw	a5,0(s1)
    80002fac:	97ba                	add	a5,a5,a4
    80002fae:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002fb0:	6d3c                	ld	a5,88(a0)
    80002fb2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002fb4:	60e2                	ld	ra,24(sp)
    80002fb6:	6442                	ld	s0,16(sp)
    80002fb8:	64a2                	ld	s1,8(sp)
    80002fba:	6105                	addi	sp,sp,32
    80002fbc:	8082                	ret
    return p->trapframe->a1;
    80002fbe:	6d3c                	ld	a5,88(a0)
    80002fc0:	7fa8                	ld	a0,120(a5)
    80002fc2:	bfcd                	j	80002fb4 <argraw+0x30>
    return p->trapframe->a2;
    80002fc4:	6d3c                	ld	a5,88(a0)
    80002fc6:	63c8                	ld	a0,128(a5)
    80002fc8:	b7f5                	j	80002fb4 <argraw+0x30>
    return p->trapframe->a3;
    80002fca:	6d3c                	ld	a5,88(a0)
    80002fcc:	67c8                	ld	a0,136(a5)
    80002fce:	b7dd                	j	80002fb4 <argraw+0x30>
    return p->trapframe->a4;
    80002fd0:	6d3c                	ld	a5,88(a0)
    80002fd2:	6bc8                	ld	a0,144(a5)
    80002fd4:	b7c5                	j	80002fb4 <argraw+0x30>
    return p->trapframe->a5;
    80002fd6:	6d3c                	ld	a5,88(a0)
    80002fd8:	6fc8                	ld	a0,152(a5)
    80002fda:	bfe9                	j	80002fb4 <argraw+0x30>
  panic("argraw");
    80002fdc:	00005517          	auipc	a0,0x5
    80002fe0:	43450513          	addi	a0,a0,1076 # 80008410 <states.0+0x148>
    80002fe4:	ffffd097          	auipc	ra,0xffffd
    80002fe8:	55a080e7          	jalr	1370(ra) # 8000053e <panic>

0000000080002fec <fetchaddr>:
{
    80002fec:	1101                	addi	sp,sp,-32
    80002fee:	ec06                	sd	ra,24(sp)
    80002ff0:	e822                	sd	s0,16(sp)
    80002ff2:	e426                	sd	s1,8(sp)
    80002ff4:	e04a                	sd	s2,0(sp)
    80002ff6:	1000                	addi	s0,sp,32
    80002ff8:	84aa                	mv	s1,a0
    80002ffa:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ffc:	fffff097          	auipc	ra,0xfffff
    80003000:	9b8080e7          	jalr	-1608(ra) # 800019b4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80003004:	653c                	ld	a5,72(a0)
    80003006:	02f4f863          	bgeu	s1,a5,80003036 <fetchaddr+0x4a>
    8000300a:	00848713          	addi	a4,s1,8
    8000300e:	02e7e663          	bltu	a5,a4,8000303a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003012:	46a1                	li	a3,8
    80003014:	8626                	mv	a2,s1
    80003016:	85ca                	mv	a1,s2
    80003018:	6928                	ld	a0,80(a0)
    8000301a:	ffffe097          	auipc	ra,0xffffe
    8000301e:	6e2080e7          	jalr	1762(ra) # 800016fc <copyin>
    80003022:	00a03533          	snez	a0,a0
    80003026:	40a00533          	neg	a0,a0
}
    8000302a:	60e2                	ld	ra,24(sp)
    8000302c:	6442                	ld	s0,16(sp)
    8000302e:	64a2                	ld	s1,8(sp)
    80003030:	6902                	ld	s2,0(sp)
    80003032:	6105                	addi	sp,sp,32
    80003034:	8082                	ret
    return -1;
    80003036:	557d                	li	a0,-1
    80003038:	bfcd                	j	8000302a <fetchaddr+0x3e>
    8000303a:	557d                	li	a0,-1
    8000303c:	b7fd                	j	8000302a <fetchaddr+0x3e>

000000008000303e <fetchstr>:
{
    8000303e:	7179                	addi	sp,sp,-48
    80003040:	f406                	sd	ra,40(sp)
    80003042:	f022                	sd	s0,32(sp)
    80003044:	ec26                	sd	s1,24(sp)
    80003046:	e84a                	sd	s2,16(sp)
    80003048:	e44e                	sd	s3,8(sp)
    8000304a:	1800                	addi	s0,sp,48
    8000304c:	892a                	mv	s2,a0
    8000304e:	84ae                	mv	s1,a1
    80003050:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003052:	fffff097          	auipc	ra,0xfffff
    80003056:	962080e7          	jalr	-1694(ra) # 800019b4 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    8000305a:	86ce                	mv	a3,s3
    8000305c:	864a                	mv	a2,s2
    8000305e:	85a6                	mv	a1,s1
    80003060:	6928                	ld	a0,80(a0)
    80003062:	ffffe097          	auipc	ra,0xffffe
    80003066:	728080e7          	jalr	1832(ra) # 8000178a <copyinstr>
    8000306a:	00054e63          	bltz	a0,80003086 <fetchstr+0x48>
  return strlen(buf);
    8000306e:	8526                	mv	a0,s1
    80003070:	ffffe097          	auipc	ra,0xffffe
    80003074:	dde080e7          	jalr	-546(ra) # 80000e4e <strlen>
}
    80003078:	70a2                	ld	ra,40(sp)
    8000307a:	7402                	ld	s0,32(sp)
    8000307c:	64e2                	ld	s1,24(sp)
    8000307e:	6942                	ld	s2,16(sp)
    80003080:	69a2                	ld	s3,8(sp)
    80003082:	6145                	addi	sp,sp,48
    80003084:	8082                	ret
    return -1;
    80003086:	557d                	li	a0,-1
    80003088:	bfc5                	j	80003078 <fetchstr+0x3a>

000000008000308a <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    8000308a:	1101                	addi	sp,sp,-32
    8000308c:	ec06                	sd	ra,24(sp)
    8000308e:	e822                	sd	s0,16(sp)
    80003090:	e426                	sd	s1,8(sp)
    80003092:	1000                	addi	s0,sp,32
    80003094:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003096:	00000097          	auipc	ra,0x0
    8000309a:	eee080e7          	jalr	-274(ra) # 80002f84 <argraw>
    8000309e:	c088                	sw	a0,0(s1)
}
    800030a0:	60e2                	ld	ra,24(sp)
    800030a2:	6442                	ld	s0,16(sp)
    800030a4:	64a2                	ld	s1,8(sp)
    800030a6:	6105                	addi	sp,sp,32
    800030a8:	8082                	ret

00000000800030aa <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800030aa:	1101                	addi	sp,sp,-32
    800030ac:	ec06                	sd	ra,24(sp)
    800030ae:	e822                	sd	s0,16(sp)
    800030b0:	e426                	sd	s1,8(sp)
    800030b2:	1000                	addi	s0,sp,32
    800030b4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030b6:	00000097          	auipc	ra,0x0
    800030ba:	ece080e7          	jalr	-306(ra) # 80002f84 <argraw>
    800030be:	e088                	sd	a0,0(s1)
}
    800030c0:	60e2                	ld	ra,24(sp)
    800030c2:	6442                	ld	s0,16(sp)
    800030c4:	64a2                	ld	s1,8(sp)
    800030c6:	6105                	addi	sp,sp,32
    800030c8:	8082                	ret

00000000800030ca <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800030ca:	7179                	addi	sp,sp,-48
    800030cc:	f406                	sd	ra,40(sp)
    800030ce:	f022                	sd	s0,32(sp)
    800030d0:	ec26                	sd	s1,24(sp)
    800030d2:	e84a                	sd	s2,16(sp)
    800030d4:	1800                	addi	s0,sp,48
    800030d6:	84ae                	mv	s1,a1
    800030d8:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800030da:	fd840593          	addi	a1,s0,-40
    800030de:	00000097          	auipc	ra,0x0
    800030e2:	fcc080e7          	jalr	-52(ra) # 800030aa <argaddr>
  return fetchstr(addr, buf, max);
    800030e6:	864a                	mv	a2,s2
    800030e8:	85a6                	mv	a1,s1
    800030ea:	fd843503          	ld	a0,-40(s0)
    800030ee:	00000097          	auipc	ra,0x0
    800030f2:	f50080e7          	jalr	-176(ra) # 8000303e <fetchstr>
}
    800030f6:	70a2                	ld	ra,40(sp)
    800030f8:	7402                	ld	s0,32(sp)
    800030fa:	64e2                	ld	s1,24(sp)
    800030fc:	6942                	ld	s2,16(sp)
    800030fe:	6145                	addi	sp,sp,48
    80003100:	8082                	ret

0000000080003102 <syscall>:
[SYS_set_policy] sys_set_policy,
};

void
syscall(void)
{
    80003102:	1101                	addi	sp,sp,-32
    80003104:	ec06                	sd	ra,24(sp)
    80003106:	e822                	sd	s0,16(sp)
    80003108:	e426                	sd	s1,8(sp)
    8000310a:	e04a                	sd	s2,0(sp)
    8000310c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000310e:	fffff097          	auipc	ra,0xfffff
    80003112:	8a6080e7          	jalr	-1882(ra) # 800019b4 <myproc>
    80003116:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003118:	05853903          	ld	s2,88(a0)
    8000311c:	0a893783          	ld	a5,168(s2)
    80003120:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003124:	37fd                	addiw	a5,a5,-1
    80003126:	4765                	li	a4,25
    80003128:	00f76f63          	bltu	a4,a5,80003146 <syscall+0x44>
    8000312c:	00369713          	slli	a4,a3,0x3
    80003130:	00005797          	auipc	a5,0x5
    80003134:	32078793          	addi	a5,a5,800 # 80008450 <syscalls>
    80003138:	97ba                	add	a5,a5,a4
    8000313a:	639c                	ld	a5,0(a5)
    8000313c:	c789                	beqz	a5,80003146 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    8000313e:	9782                	jalr	a5
    80003140:	06a93823          	sd	a0,112(s2)
    80003144:	a839                	j	80003162 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003146:	15848613          	addi	a2,s1,344
    8000314a:	588c                	lw	a1,48(s1)
    8000314c:	00005517          	auipc	a0,0x5
    80003150:	2cc50513          	addi	a0,a0,716 # 80008418 <states.0+0x150>
    80003154:	ffffd097          	auipc	ra,0xffffd
    80003158:	434080e7          	jalr	1076(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000315c:	6cbc                	ld	a5,88(s1)
    8000315e:	577d                	li	a4,-1
    80003160:	fbb8                	sd	a4,112(a5)
  }
}
    80003162:	60e2                	ld	ra,24(sp)
    80003164:	6442                	ld	s0,16(sp)
    80003166:	64a2                	ld	s1,8(sp)
    80003168:	6902                	ld	s2,0(sp)
    8000316a:	6105                	addi	sp,sp,32
    8000316c:	8082                	ret

000000008000316e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000316e:	7139                	addi	sp,sp,-64
    80003170:	fc06                	sd	ra,56(sp)
    80003172:	f822                	sd	s0,48(sp)
    80003174:	0080                	addi	s0,sp,64
  int n;
  char exit_msg[32];
  argint(0, &n);
    80003176:	fec40593          	addi	a1,s0,-20
    8000317a:	4501                	li	a0,0
    8000317c:	00000097          	auipc	ra,0x0
    80003180:	f0e080e7          	jalr	-242(ra) # 8000308a <argint>
  argstr(1, exit_msg, 32);
    80003184:	02000613          	li	a2,32
    80003188:	fc840593          	addi	a1,s0,-56
    8000318c:	4505                	li	a0,1
    8000318e:	00000097          	auipc	ra,0x0
    80003192:	f3c080e7          	jalr	-196(ra) # 800030ca <argstr>
  exit(n, exit_msg);
    80003196:	fc840593          	addi	a1,s0,-56
    8000319a:	fec42503          	lw	a0,-20(s0)
    8000319e:	fffff097          	auipc	ra,0xfffff
    800031a2:	ffa080e7          	jalr	-6(ra) # 80002198 <exit>
  return 0; // not reached
}
    800031a6:	4501                	li	a0,0
    800031a8:	70e2                	ld	ra,56(sp)
    800031aa:	7442                	ld	s0,48(sp)
    800031ac:	6121                	addi	sp,sp,64
    800031ae:	8082                	ret

00000000800031b0 <sys_getpid>:

uint64
sys_getpid(void)
{
    800031b0:	1141                	addi	sp,sp,-16
    800031b2:	e406                	sd	ra,8(sp)
    800031b4:	e022                	sd	s0,0(sp)
    800031b6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800031b8:	ffffe097          	auipc	ra,0xffffe
    800031bc:	7fc080e7          	jalr	2044(ra) # 800019b4 <myproc>
}
    800031c0:	5908                	lw	a0,48(a0)
    800031c2:	60a2                	ld	ra,8(sp)
    800031c4:	6402                	ld	s0,0(sp)
    800031c6:	0141                	addi	sp,sp,16
    800031c8:	8082                	ret

00000000800031ca <sys_fork>:

uint64
sys_fork(void)
{
    800031ca:	1141                	addi	sp,sp,-16
    800031cc:	e406                	sd	ra,8(sp)
    800031ce:	e022                	sd	s0,0(sp)
    800031d0:	0800                	addi	s0,sp,16
  return fork();
    800031d2:	fffff097          	auipc	ra,0xfffff
    800031d6:	bae080e7          	jalr	-1106(ra) # 80001d80 <fork>
}
    800031da:	60a2                	ld	ra,8(sp)
    800031dc:	6402                	ld	s0,0(sp)
    800031de:	0141                	addi	sp,sp,16
    800031e0:	8082                	ret

00000000800031e2 <sys_wait>:

uint64
sys_wait(void)
{
    800031e2:	1101                	addi	sp,sp,-32
    800031e4:	ec06                	sd	ra,24(sp)
    800031e6:	e822                	sd	s0,16(sp)
    800031e8:	1000                	addi	s0,sp,32
  uint64 p;
  uint64 addr;
  argaddr(0, &p);
    800031ea:	fe840593          	addi	a1,s0,-24
    800031ee:	4501                	li	a0,0
    800031f0:	00000097          	auipc	ra,0x0
    800031f4:	eba080e7          	jalr	-326(ra) # 800030aa <argaddr>
  argaddr(1, &addr);
    800031f8:	fe040593          	addi	a1,s0,-32
    800031fc:	4505                	li	a0,1
    800031fe:	00000097          	auipc	ra,0x0
    80003202:	eac080e7          	jalr	-340(ra) # 800030aa <argaddr>
  return wait(p, addr);
    80003206:	fe043583          	ld	a1,-32(s0)
    8000320a:	fe843503          	ld	a0,-24(s0)
    8000320e:	fffff097          	auipc	ra,0xfffff
    80003212:	142080e7          	jalr	322(ra) # 80002350 <wait>
}
    80003216:	60e2                	ld	ra,24(sp)
    80003218:	6442                	ld	s0,16(sp)
    8000321a:	6105                	addi	sp,sp,32
    8000321c:	8082                	ret

000000008000321e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000321e:	7179                	addi	sp,sp,-48
    80003220:	f406                	sd	ra,40(sp)
    80003222:	f022                	sd	s0,32(sp)
    80003224:	ec26                	sd	s1,24(sp)
    80003226:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003228:	fdc40593          	addi	a1,s0,-36
    8000322c:	4501                	li	a0,0
    8000322e:	00000097          	auipc	ra,0x0
    80003232:	e5c080e7          	jalr	-420(ra) # 8000308a <argint>
  addr = myproc()->sz;
    80003236:	ffffe097          	auipc	ra,0xffffe
    8000323a:	77e080e7          	jalr	1918(ra) # 800019b4 <myproc>
    8000323e:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80003240:	fdc42503          	lw	a0,-36(s0)
    80003244:	fffff097          	auipc	ra,0xfffff
    80003248:	ae0080e7          	jalr	-1312(ra) # 80001d24 <growproc>
    8000324c:	00054863          	bltz	a0,8000325c <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003250:	8526                	mv	a0,s1
    80003252:	70a2                	ld	ra,40(sp)
    80003254:	7402                	ld	s0,32(sp)
    80003256:	64e2                	ld	s1,24(sp)
    80003258:	6145                	addi	sp,sp,48
    8000325a:	8082                	ret
    return -1;
    8000325c:	54fd                	li	s1,-1
    8000325e:	bfcd                	j	80003250 <sys_sbrk+0x32>

0000000080003260 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003260:	7139                	addi	sp,sp,-64
    80003262:	fc06                	sd	ra,56(sp)
    80003264:	f822                	sd	s0,48(sp)
    80003266:	f426                	sd	s1,40(sp)
    80003268:	f04a                	sd	s2,32(sp)
    8000326a:	ec4e                	sd	s3,24(sp)
    8000326c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    8000326e:	fcc40593          	addi	a1,s0,-52
    80003272:	4501                	li	a0,0
    80003274:	00000097          	auipc	ra,0x0
    80003278:	e16080e7          	jalr	-490(ra) # 8000308a <argint>
  acquire(&tickslock);
    8000327c:	00015517          	auipc	a0,0x15
    80003280:	93450513          	addi	a0,a0,-1740 # 80017bb0 <tickslock>
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	952080e7          	jalr	-1710(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    8000328c:	00005917          	auipc	s2,0x5
    80003290:	68c92903          	lw	s2,1676(s2) # 80008918 <ticks>
  while (ticks - ticks0 < n)
    80003294:	fcc42783          	lw	a5,-52(s0)
    80003298:	cf9d                	beqz	a5,800032d6 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000329a:	00015997          	auipc	s3,0x15
    8000329e:	91698993          	addi	s3,s3,-1770 # 80017bb0 <tickslock>
    800032a2:	00005497          	auipc	s1,0x5
    800032a6:	67648493          	addi	s1,s1,1654 # 80008918 <ticks>
    if (killed(myproc()))
    800032aa:	ffffe097          	auipc	ra,0xffffe
    800032ae:	70a080e7          	jalr	1802(ra) # 800019b4 <myproc>
    800032b2:	fffff097          	auipc	ra,0xfffff
    800032b6:	06c080e7          	jalr	108(ra) # 8000231e <killed>
    800032ba:	ed15                	bnez	a0,800032f6 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800032bc:	85ce                	mv	a1,s3
    800032be:	8526                	mv	a0,s1
    800032c0:	fffff097          	auipc	ra,0xfffff
    800032c4:	da4080e7          	jalr	-604(ra) # 80002064 <sleep>
  while (ticks - ticks0 < n)
    800032c8:	409c                	lw	a5,0(s1)
    800032ca:	412787bb          	subw	a5,a5,s2
    800032ce:	fcc42703          	lw	a4,-52(s0)
    800032d2:	fce7ece3          	bltu	a5,a4,800032aa <sys_sleep+0x4a>
  }
  release(&tickslock);
    800032d6:	00015517          	auipc	a0,0x15
    800032da:	8da50513          	addi	a0,a0,-1830 # 80017bb0 <tickslock>
    800032de:	ffffe097          	auipc	ra,0xffffe
    800032e2:	9ac080e7          	jalr	-1620(ra) # 80000c8a <release>
  return 0;
    800032e6:	4501                	li	a0,0
}
    800032e8:	70e2                	ld	ra,56(sp)
    800032ea:	7442                	ld	s0,48(sp)
    800032ec:	74a2                	ld	s1,40(sp)
    800032ee:	7902                	ld	s2,32(sp)
    800032f0:	69e2                	ld	s3,24(sp)
    800032f2:	6121                	addi	sp,sp,64
    800032f4:	8082                	ret
      release(&tickslock);
    800032f6:	00015517          	auipc	a0,0x15
    800032fa:	8ba50513          	addi	a0,a0,-1862 # 80017bb0 <tickslock>
    800032fe:	ffffe097          	auipc	ra,0xffffe
    80003302:	98c080e7          	jalr	-1652(ra) # 80000c8a <release>
      return -1;
    80003306:	557d                	li	a0,-1
    80003308:	b7c5                	j	800032e8 <sys_sleep+0x88>

000000008000330a <sys_kill>:

uint64
sys_kill(void)
{
    8000330a:	1101                	addi	sp,sp,-32
    8000330c:	ec06                	sd	ra,24(sp)
    8000330e:	e822                	sd	s0,16(sp)
    80003310:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003312:	fec40593          	addi	a1,s0,-20
    80003316:	4501                	li	a0,0
    80003318:	00000097          	auipc	ra,0x0
    8000331c:	d72080e7          	jalr	-654(ra) # 8000308a <argint>
  return kill(pid);
    80003320:	fec42503          	lw	a0,-20(s0)
    80003324:	fffff097          	auipc	ra,0xfffff
    80003328:	f5c080e7          	jalr	-164(ra) # 80002280 <kill>
}
    8000332c:	60e2                	ld	ra,24(sp)
    8000332e:	6442                	ld	s0,16(sp)
    80003330:	6105                	addi	sp,sp,32
    80003332:	8082                	ret

0000000080003334 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003334:	1101                	addi	sp,sp,-32
    80003336:	ec06                	sd	ra,24(sp)
    80003338:	e822                	sd	s0,16(sp)
    8000333a:	e426                	sd	s1,8(sp)
    8000333c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000333e:	00015517          	auipc	a0,0x15
    80003342:	87250513          	addi	a0,a0,-1934 # 80017bb0 <tickslock>
    80003346:	ffffe097          	auipc	ra,0xffffe
    8000334a:	890080e7          	jalr	-1904(ra) # 80000bd6 <acquire>
  xticks = ticks;
    8000334e:	00005497          	auipc	s1,0x5
    80003352:	5ca4a483          	lw	s1,1482(s1) # 80008918 <ticks>
  release(&tickslock);
    80003356:	00015517          	auipc	a0,0x15
    8000335a:	85a50513          	addi	a0,a0,-1958 # 80017bb0 <tickslock>
    8000335e:	ffffe097          	auipc	ra,0xffffe
    80003362:	92c080e7          	jalr	-1748(ra) # 80000c8a <release>
  return xticks;
}
    80003366:	02049513          	slli	a0,s1,0x20
    8000336a:	9101                	srli	a0,a0,0x20
    8000336c:	60e2                	ld	ra,24(sp)
    8000336e:	6442                	ld	s0,16(sp)
    80003370:	64a2                	ld	s1,8(sp)
    80003372:	6105                	addi	sp,sp,32
    80003374:	8082                	ret

0000000080003376 <sys_memsize>:
// task2 - memsize()
uint64
sys_memsize(void)
{
    80003376:	1141                	addi	sp,sp,-16
    80003378:	e406                	sd	ra,8(sp)
    8000337a:	e022                	sd	s0,0(sp)
    8000337c:	0800                	addi	s0,sp,16
  return myproc()->sz;
    8000337e:	ffffe097          	auipc	ra,0xffffe
    80003382:	636080e7          	jalr	1590(ra) # 800019b4 <myproc>
}
    80003386:	6528                	ld	a0,72(a0)
    80003388:	60a2                	ld	ra,8(sp)
    8000338a:	6402                	ld	s0,0(sp)
    8000338c:	0141                	addi	sp,sp,16
    8000338e:	8082                	ret

0000000080003390 <sys_set_ps_priority>:
// task 5 
uint64 
sys_set_ps_priority(void)
{
    80003390:	1101                	addi	sp,sp,-32
    80003392:	ec06                	sd	ra,24(sp)
    80003394:	e822                	sd	s0,16(sp)
    80003396:	1000                	addi	s0,sp,32
  int priority; 
  argint(0, &priority);
    80003398:	fec40593          	addi	a1,s0,-20
    8000339c:	4501                	li	a0,0
    8000339e:	00000097          	auipc	ra,0x0
    800033a2:	cec080e7          	jalr	-788(ra) # 8000308a <argint>
  set_ps_priority(priority);
    800033a6:	fec42503          	lw	a0,-20(s0)
    800033aa:	fffff097          	auipc	ra,0xfffff
    800033ae:	26e080e7          	jalr	622(ra) # 80002618 <set_ps_priority>
  return priority;
}
    800033b2:	fec42503          	lw	a0,-20(s0)
    800033b6:	60e2                	ld	ra,24(sp)
    800033b8:	6442                	ld	s0,16(sp)
    800033ba:	6105                	addi	sp,sp,32
    800033bc:	8082                	ret

00000000800033be <sys_set_cfs_priority>:

uint64
sys_set_cfs_priority(void)
{
    800033be:	1101                	addi	sp,sp,-32
    800033c0:	ec06                	sd	ra,24(sp)
    800033c2:	e822                	sd	s0,16(sp)
    800033c4:	1000                	addi	s0,sp,32
  int priority; 
  argint(0, &priority);
    800033c6:	fec40593          	addi	a1,s0,-20
    800033ca:	4501                	li	a0,0
    800033cc:	00000097          	auipc	ra,0x0
    800033d0:	cbe080e7          	jalr	-834(ra) # 8000308a <argint>
  if (priority != 0 && priority != 1 && priority != 2 )
    800033d4:	fec42783          	lw	a5,-20(s0)
    800033d8:	0007869b          	sext.w	a3,a5
    800033dc:	4709                	li	a4,2
  {
    return -1;
    800033de:	557d                	li	a0,-1
  if (priority != 0 && priority != 1 && priority != 2 )
    800033e0:	00d76863          	bltu	a4,a3,800033f0 <sys_set_cfs_priority+0x32>
  }
  set_cfs_priority(priority);
    800033e4:	853e                	mv	a0,a5
    800033e6:	fffff097          	auipc	ra,0xfffff
    800033ea:	61c080e7          	jalr	1564(ra) # 80002a02 <set_cfs_priority>
  return 0; 
    800033ee:	4501                	li	a0,0
}
    800033f0:	60e2                	ld	ra,24(sp)
    800033f2:	6442                	ld	s0,16(sp)
    800033f4:	6105                	addi	sp,sp,32
    800033f6:	8082                	ret

00000000800033f8 <sys_get_cfs_stats>:

uint64
sys_get_cfs_stats(void)
{
    800033f8:	1101                	addi	sp,sp,-32
    800033fa:	ec06                	sd	ra,24(sp)
    800033fc:	e822                	sd	s0,16(sp)
    800033fe:	1000                	addi	s0,sp,32
  int pid; 
  uint64 dst;
  argint(0, &pid);
    80003400:	fec40593          	addi	a1,s0,-20
    80003404:	4501                	li	a0,0
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	c84080e7          	jalr	-892(ra) # 8000308a <argint>
  argaddr(1, &dst);
    8000340e:	fe040593          	addi	a1,s0,-32
    80003412:	4505                	li	a0,1
    80003414:	00000097          	auipc	ra,0x0
    80003418:	c96080e7          	jalr	-874(ra) # 800030aa <argaddr>
  return get_cfs_priority(pid, dst);
    8000341c:	fe043583          	ld	a1,-32(s0)
    80003420:	fec42503          	lw	a0,-20(s0)
    80003424:	fffff097          	auipc	ra,0xfffff
    80003428:	600080e7          	jalr	1536(ra) # 80002a24 <get_cfs_priority>
}
    8000342c:	60e2                	ld	ra,24(sp)
    8000342e:	6442                	ld	s0,16(sp)
    80003430:	6105                	addi	sp,sp,32
    80003432:	8082                	ret

0000000080003434 <sys_set_policy>:
uint64
sys_set_policy(void)
{
    80003434:	1101                	addi	sp,sp,-32
    80003436:	ec06                	sd	ra,24(sp)
    80003438:	e822                	sd	s0,16(sp)
    8000343a:	1000                	addi	s0,sp,32
  int policy; 
  argint(0, &policy);
    8000343c:	fec40593          	addi	a1,s0,-20
    80003440:	4501                	li	a0,0
    80003442:	00000097          	auipc	ra,0x0
    80003446:	c48080e7          	jalr	-952(ra) # 8000308a <argint>
  if (policy != 0 && policy != 1 && policy != 2 )
    8000344a:	fec42783          	lw	a5,-20(s0)
    8000344e:	0007869b          	sext.w	a3,a5
    80003452:	4709                	li	a4,2
  {
    return -1;
    80003454:	557d                	li	a0,-1
  if (policy != 0 && policy != 1 && policy != 2 )
    80003456:	00d76863          	bltu	a4,a3,80003466 <sys_set_policy+0x32>
  }
  set_policy(policy);
    8000345a:	853e                	mv	a0,a5
    8000345c:	fffff097          	auipc	ra,0xfffff
    80003460:	6b8080e7          	jalr	1720(ra) # 80002b14 <set_policy>
  return 0; 
    80003464:	4501                	li	a0,0
    80003466:	60e2                	ld	ra,24(sp)
    80003468:	6442                	ld	s0,16(sp)
    8000346a:	6105                	addi	sp,sp,32
    8000346c:	8082                	ret

000000008000346e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000346e:	7179                	addi	sp,sp,-48
    80003470:	f406                	sd	ra,40(sp)
    80003472:	f022                	sd	s0,32(sp)
    80003474:	ec26                	sd	s1,24(sp)
    80003476:	e84a                	sd	s2,16(sp)
    80003478:	e44e                	sd	s3,8(sp)
    8000347a:	e052                	sd	s4,0(sp)
    8000347c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000347e:	00005597          	auipc	a1,0x5
    80003482:	0aa58593          	addi	a1,a1,170 # 80008528 <syscalls+0xd8>
    80003486:	00014517          	auipc	a0,0x14
    8000348a:	74250513          	addi	a0,a0,1858 # 80017bc8 <bcache>
    8000348e:	ffffd097          	auipc	ra,0xffffd
    80003492:	6b8080e7          	jalr	1720(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003496:	0001c797          	auipc	a5,0x1c
    8000349a:	73278793          	addi	a5,a5,1842 # 8001fbc8 <bcache+0x8000>
    8000349e:	0001d717          	auipc	a4,0x1d
    800034a2:	99270713          	addi	a4,a4,-1646 # 8001fe30 <bcache+0x8268>
    800034a6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800034aa:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034ae:	00014497          	auipc	s1,0x14
    800034b2:	73248493          	addi	s1,s1,1842 # 80017be0 <bcache+0x18>
    b->next = bcache.head.next;
    800034b6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800034b8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800034ba:	00005a17          	auipc	s4,0x5
    800034be:	076a0a13          	addi	s4,s4,118 # 80008530 <syscalls+0xe0>
    b->next = bcache.head.next;
    800034c2:	2b893783          	ld	a5,696(s2)
    800034c6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800034c8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800034cc:	85d2                	mv	a1,s4
    800034ce:	01048513          	addi	a0,s1,16
    800034d2:	00001097          	auipc	ra,0x1
    800034d6:	4c4080e7          	jalr	1220(ra) # 80004996 <initsleeplock>
    bcache.head.next->prev = b;
    800034da:	2b893783          	ld	a5,696(s2)
    800034de:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800034e0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034e4:	45848493          	addi	s1,s1,1112
    800034e8:	fd349de3          	bne	s1,s3,800034c2 <binit+0x54>
  }
}
    800034ec:	70a2                	ld	ra,40(sp)
    800034ee:	7402                	ld	s0,32(sp)
    800034f0:	64e2                	ld	s1,24(sp)
    800034f2:	6942                	ld	s2,16(sp)
    800034f4:	69a2                	ld	s3,8(sp)
    800034f6:	6a02                	ld	s4,0(sp)
    800034f8:	6145                	addi	sp,sp,48
    800034fa:	8082                	ret

00000000800034fc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800034fc:	7179                	addi	sp,sp,-48
    800034fe:	f406                	sd	ra,40(sp)
    80003500:	f022                	sd	s0,32(sp)
    80003502:	ec26                	sd	s1,24(sp)
    80003504:	e84a                	sd	s2,16(sp)
    80003506:	e44e                	sd	s3,8(sp)
    80003508:	1800                	addi	s0,sp,48
    8000350a:	892a                	mv	s2,a0
    8000350c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000350e:	00014517          	auipc	a0,0x14
    80003512:	6ba50513          	addi	a0,a0,1722 # 80017bc8 <bcache>
    80003516:	ffffd097          	auipc	ra,0xffffd
    8000351a:	6c0080e7          	jalr	1728(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000351e:	0001d497          	auipc	s1,0x1d
    80003522:	9624b483          	ld	s1,-1694(s1) # 8001fe80 <bcache+0x82b8>
    80003526:	0001d797          	auipc	a5,0x1d
    8000352a:	90a78793          	addi	a5,a5,-1782 # 8001fe30 <bcache+0x8268>
    8000352e:	02f48f63          	beq	s1,a5,8000356c <bread+0x70>
    80003532:	873e                	mv	a4,a5
    80003534:	a021                	j	8000353c <bread+0x40>
    80003536:	68a4                	ld	s1,80(s1)
    80003538:	02e48a63          	beq	s1,a4,8000356c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000353c:	449c                	lw	a5,8(s1)
    8000353e:	ff279ce3          	bne	a5,s2,80003536 <bread+0x3a>
    80003542:	44dc                	lw	a5,12(s1)
    80003544:	ff3799e3          	bne	a5,s3,80003536 <bread+0x3a>
      b->refcnt++;
    80003548:	40bc                	lw	a5,64(s1)
    8000354a:	2785                	addiw	a5,a5,1
    8000354c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000354e:	00014517          	auipc	a0,0x14
    80003552:	67a50513          	addi	a0,a0,1658 # 80017bc8 <bcache>
    80003556:	ffffd097          	auipc	ra,0xffffd
    8000355a:	734080e7          	jalr	1844(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000355e:	01048513          	addi	a0,s1,16
    80003562:	00001097          	auipc	ra,0x1
    80003566:	46e080e7          	jalr	1134(ra) # 800049d0 <acquiresleep>
      return b;
    8000356a:	a8b9                	j	800035c8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000356c:	0001d497          	auipc	s1,0x1d
    80003570:	90c4b483          	ld	s1,-1780(s1) # 8001fe78 <bcache+0x82b0>
    80003574:	0001d797          	auipc	a5,0x1d
    80003578:	8bc78793          	addi	a5,a5,-1860 # 8001fe30 <bcache+0x8268>
    8000357c:	00f48863          	beq	s1,a5,8000358c <bread+0x90>
    80003580:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003582:	40bc                	lw	a5,64(s1)
    80003584:	cf81                	beqz	a5,8000359c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003586:	64a4                	ld	s1,72(s1)
    80003588:	fee49de3          	bne	s1,a4,80003582 <bread+0x86>
  panic("bget: no buffers");
    8000358c:	00005517          	auipc	a0,0x5
    80003590:	fac50513          	addi	a0,a0,-84 # 80008538 <syscalls+0xe8>
    80003594:	ffffd097          	auipc	ra,0xffffd
    80003598:	faa080e7          	jalr	-86(ra) # 8000053e <panic>
      b->dev = dev;
    8000359c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800035a0:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800035a4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800035a8:	4785                	li	a5,1
    800035aa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035ac:	00014517          	auipc	a0,0x14
    800035b0:	61c50513          	addi	a0,a0,1564 # 80017bc8 <bcache>
    800035b4:	ffffd097          	auipc	ra,0xffffd
    800035b8:	6d6080e7          	jalr	1750(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800035bc:	01048513          	addi	a0,s1,16
    800035c0:	00001097          	auipc	ra,0x1
    800035c4:	410080e7          	jalr	1040(ra) # 800049d0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800035c8:	409c                	lw	a5,0(s1)
    800035ca:	cb89                	beqz	a5,800035dc <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800035cc:	8526                	mv	a0,s1
    800035ce:	70a2                	ld	ra,40(sp)
    800035d0:	7402                	ld	s0,32(sp)
    800035d2:	64e2                	ld	s1,24(sp)
    800035d4:	6942                	ld	s2,16(sp)
    800035d6:	69a2                	ld	s3,8(sp)
    800035d8:	6145                	addi	sp,sp,48
    800035da:	8082                	ret
    virtio_disk_rw(b, 0);
    800035dc:	4581                	li	a1,0
    800035de:	8526                	mv	a0,s1
    800035e0:	00003097          	auipc	ra,0x3
    800035e4:	fd4080e7          	jalr	-44(ra) # 800065b4 <virtio_disk_rw>
    b->valid = 1;
    800035e8:	4785                	li	a5,1
    800035ea:	c09c                	sw	a5,0(s1)
  return b;
    800035ec:	b7c5                	j	800035cc <bread+0xd0>

00000000800035ee <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800035ee:	1101                	addi	sp,sp,-32
    800035f0:	ec06                	sd	ra,24(sp)
    800035f2:	e822                	sd	s0,16(sp)
    800035f4:	e426                	sd	s1,8(sp)
    800035f6:	1000                	addi	s0,sp,32
    800035f8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035fa:	0541                	addi	a0,a0,16
    800035fc:	00001097          	auipc	ra,0x1
    80003600:	46e080e7          	jalr	1134(ra) # 80004a6a <holdingsleep>
    80003604:	cd01                	beqz	a0,8000361c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003606:	4585                	li	a1,1
    80003608:	8526                	mv	a0,s1
    8000360a:	00003097          	auipc	ra,0x3
    8000360e:	faa080e7          	jalr	-86(ra) # 800065b4 <virtio_disk_rw>
}
    80003612:	60e2                	ld	ra,24(sp)
    80003614:	6442                	ld	s0,16(sp)
    80003616:	64a2                	ld	s1,8(sp)
    80003618:	6105                	addi	sp,sp,32
    8000361a:	8082                	ret
    panic("bwrite");
    8000361c:	00005517          	auipc	a0,0x5
    80003620:	f3450513          	addi	a0,a0,-204 # 80008550 <syscalls+0x100>
    80003624:	ffffd097          	auipc	ra,0xffffd
    80003628:	f1a080e7          	jalr	-230(ra) # 8000053e <panic>

000000008000362c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000362c:	1101                	addi	sp,sp,-32
    8000362e:	ec06                	sd	ra,24(sp)
    80003630:	e822                	sd	s0,16(sp)
    80003632:	e426                	sd	s1,8(sp)
    80003634:	e04a                	sd	s2,0(sp)
    80003636:	1000                	addi	s0,sp,32
    80003638:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000363a:	01050913          	addi	s2,a0,16
    8000363e:	854a                	mv	a0,s2
    80003640:	00001097          	auipc	ra,0x1
    80003644:	42a080e7          	jalr	1066(ra) # 80004a6a <holdingsleep>
    80003648:	c92d                	beqz	a0,800036ba <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000364a:	854a                	mv	a0,s2
    8000364c:	00001097          	auipc	ra,0x1
    80003650:	3da080e7          	jalr	986(ra) # 80004a26 <releasesleep>

  acquire(&bcache.lock);
    80003654:	00014517          	auipc	a0,0x14
    80003658:	57450513          	addi	a0,a0,1396 # 80017bc8 <bcache>
    8000365c:	ffffd097          	auipc	ra,0xffffd
    80003660:	57a080e7          	jalr	1402(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003664:	40bc                	lw	a5,64(s1)
    80003666:	37fd                	addiw	a5,a5,-1
    80003668:	0007871b          	sext.w	a4,a5
    8000366c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000366e:	eb05                	bnez	a4,8000369e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003670:	68bc                	ld	a5,80(s1)
    80003672:	64b8                	ld	a4,72(s1)
    80003674:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003676:	64bc                	ld	a5,72(s1)
    80003678:	68b8                	ld	a4,80(s1)
    8000367a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000367c:	0001c797          	auipc	a5,0x1c
    80003680:	54c78793          	addi	a5,a5,1356 # 8001fbc8 <bcache+0x8000>
    80003684:	2b87b703          	ld	a4,696(a5)
    80003688:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000368a:	0001c717          	auipc	a4,0x1c
    8000368e:	7a670713          	addi	a4,a4,1958 # 8001fe30 <bcache+0x8268>
    80003692:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003694:	2b87b703          	ld	a4,696(a5)
    80003698:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000369a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000369e:	00014517          	auipc	a0,0x14
    800036a2:	52a50513          	addi	a0,a0,1322 # 80017bc8 <bcache>
    800036a6:	ffffd097          	auipc	ra,0xffffd
    800036aa:	5e4080e7          	jalr	1508(ra) # 80000c8a <release>
}
    800036ae:	60e2                	ld	ra,24(sp)
    800036b0:	6442                	ld	s0,16(sp)
    800036b2:	64a2                	ld	s1,8(sp)
    800036b4:	6902                	ld	s2,0(sp)
    800036b6:	6105                	addi	sp,sp,32
    800036b8:	8082                	ret
    panic("brelse");
    800036ba:	00005517          	auipc	a0,0x5
    800036be:	e9e50513          	addi	a0,a0,-354 # 80008558 <syscalls+0x108>
    800036c2:	ffffd097          	auipc	ra,0xffffd
    800036c6:	e7c080e7          	jalr	-388(ra) # 8000053e <panic>

00000000800036ca <bpin>:

void
bpin(struct buf *b) {
    800036ca:	1101                	addi	sp,sp,-32
    800036cc:	ec06                	sd	ra,24(sp)
    800036ce:	e822                	sd	s0,16(sp)
    800036d0:	e426                	sd	s1,8(sp)
    800036d2:	1000                	addi	s0,sp,32
    800036d4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036d6:	00014517          	auipc	a0,0x14
    800036da:	4f250513          	addi	a0,a0,1266 # 80017bc8 <bcache>
    800036de:	ffffd097          	auipc	ra,0xffffd
    800036e2:	4f8080e7          	jalr	1272(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800036e6:	40bc                	lw	a5,64(s1)
    800036e8:	2785                	addiw	a5,a5,1
    800036ea:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036ec:	00014517          	auipc	a0,0x14
    800036f0:	4dc50513          	addi	a0,a0,1244 # 80017bc8 <bcache>
    800036f4:	ffffd097          	auipc	ra,0xffffd
    800036f8:	596080e7          	jalr	1430(ra) # 80000c8a <release>
}
    800036fc:	60e2                	ld	ra,24(sp)
    800036fe:	6442                	ld	s0,16(sp)
    80003700:	64a2                	ld	s1,8(sp)
    80003702:	6105                	addi	sp,sp,32
    80003704:	8082                	ret

0000000080003706 <bunpin>:

void
bunpin(struct buf *b) {
    80003706:	1101                	addi	sp,sp,-32
    80003708:	ec06                	sd	ra,24(sp)
    8000370a:	e822                	sd	s0,16(sp)
    8000370c:	e426                	sd	s1,8(sp)
    8000370e:	1000                	addi	s0,sp,32
    80003710:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003712:	00014517          	auipc	a0,0x14
    80003716:	4b650513          	addi	a0,a0,1206 # 80017bc8 <bcache>
    8000371a:	ffffd097          	auipc	ra,0xffffd
    8000371e:	4bc080e7          	jalr	1212(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003722:	40bc                	lw	a5,64(s1)
    80003724:	37fd                	addiw	a5,a5,-1
    80003726:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003728:	00014517          	auipc	a0,0x14
    8000372c:	4a050513          	addi	a0,a0,1184 # 80017bc8 <bcache>
    80003730:	ffffd097          	auipc	ra,0xffffd
    80003734:	55a080e7          	jalr	1370(ra) # 80000c8a <release>
}
    80003738:	60e2                	ld	ra,24(sp)
    8000373a:	6442                	ld	s0,16(sp)
    8000373c:	64a2                	ld	s1,8(sp)
    8000373e:	6105                	addi	sp,sp,32
    80003740:	8082                	ret

0000000080003742 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003742:	1101                	addi	sp,sp,-32
    80003744:	ec06                	sd	ra,24(sp)
    80003746:	e822                	sd	s0,16(sp)
    80003748:	e426                	sd	s1,8(sp)
    8000374a:	e04a                	sd	s2,0(sp)
    8000374c:	1000                	addi	s0,sp,32
    8000374e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003750:	00d5d59b          	srliw	a1,a1,0xd
    80003754:	0001d797          	auipc	a5,0x1d
    80003758:	b507a783          	lw	a5,-1200(a5) # 800202a4 <sb+0x1c>
    8000375c:	9dbd                	addw	a1,a1,a5
    8000375e:	00000097          	auipc	ra,0x0
    80003762:	d9e080e7          	jalr	-610(ra) # 800034fc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003766:	0074f713          	andi	a4,s1,7
    8000376a:	4785                	li	a5,1
    8000376c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003770:	14ce                	slli	s1,s1,0x33
    80003772:	90d9                	srli	s1,s1,0x36
    80003774:	00950733          	add	a4,a0,s1
    80003778:	05874703          	lbu	a4,88(a4)
    8000377c:	00e7f6b3          	and	a3,a5,a4
    80003780:	c69d                	beqz	a3,800037ae <bfree+0x6c>
    80003782:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003784:	94aa                	add	s1,s1,a0
    80003786:	fff7c793          	not	a5,a5
    8000378a:	8ff9                	and	a5,a5,a4
    8000378c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003790:	00001097          	auipc	ra,0x1
    80003794:	120080e7          	jalr	288(ra) # 800048b0 <log_write>
  brelse(bp);
    80003798:	854a                	mv	a0,s2
    8000379a:	00000097          	auipc	ra,0x0
    8000379e:	e92080e7          	jalr	-366(ra) # 8000362c <brelse>
}
    800037a2:	60e2                	ld	ra,24(sp)
    800037a4:	6442                	ld	s0,16(sp)
    800037a6:	64a2                	ld	s1,8(sp)
    800037a8:	6902                	ld	s2,0(sp)
    800037aa:	6105                	addi	sp,sp,32
    800037ac:	8082                	ret
    panic("freeing free block");
    800037ae:	00005517          	auipc	a0,0x5
    800037b2:	db250513          	addi	a0,a0,-590 # 80008560 <syscalls+0x110>
    800037b6:	ffffd097          	auipc	ra,0xffffd
    800037ba:	d88080e7          	jalr	-632(ra) # 8000053e <panic>

00000000800037be <balloc>:
{
    800037be:	711d                	addi	sp,sp,-96
    800037c0:	ec86                	sd	ra,88(sp)
    800037c2:	e8a2                	sd	s0,80(sp)
    800037c4:	e4a6                	sd	s1,72(sp)
    800037c6:	e0ca                	sd	s2,64(sp)
    800037c8:	fc4e                	sd	s3,56(sp)
    800037ca:	f852                	sd	s4,48(sp)
    800037cc:	f456                	sd	s5,40(sp)
    800037ce:	f05a                	sd	s6,32(sp)
    800037d0:	ec5e                	sd	s7,24(sp)
    800037d2:	e862                	sd	s8,16(sp)
    800037d4:	e466                	sd	s9,8(sp)
    800037d6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800037d8:	0001d797          	auipc	a5,0x1d
    800037dc:	ab47a783          	lw	a5,-1356(a5) # 8002028c <sb+0x4>
    800037e0:	10078163          	beqz	a5,800038e2 <balloc+0x124>
    800037e4:	8baa                	mv	s7,a0
    800037e6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800037e8:	0001db17          	auipc	s6,0x1d
    800037ec:	aa0b0b13          	addi	s6,s6,-1376 # 80020288 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037f0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800037f2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037f4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800037f6:	6c89                	lui	s9,0x2
    800037f8:	a061                	j	80003880 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800037fa:	974a                	add	a4,a4,s2
    800037fc:	8fd5                	or	a5,a5,a3
    800037fe:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003802:	854a                	mv	a0,s2
    80003804:	00001097          	auipc	ra,0x1
    80003808:	0ac080e7          	jalr	172(ra) # 800048b0 <log_write>
        brelse(bp);
    8000380c:	854a                	mv	a0,s2
    8000380e:	00000097          	auipc	ra,0x0
    80003812:	e1e080e7          	jalr	-482(ra) # 8000362c <brelse>
  bp = bread(dev, bno);
    80003816:	85a6                	mv	a1,s1
    80003818:	855e                	mv	a0,s7
    8000381a:	00000097          	auipc	ra,0x0
    8000381e:	ce2080e7          	jalr	-798(ra) # 800034fc <bread>
    80003822:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003824:	40000613          	li	a2,1024
    80003828:	4581                	li	a1,0
    8000382a:	05850513          	addi	a0,a0,88
    8000382e:	ffffd097          	auipc	ra,0xffffd
    80003832:	4a4080e7          	jalr	1188(ra) # 80000cd2 <memset>
  log_write(bp);
    80003836:	854a                	mv	a0,s2
    80003838:	00001097          	auipc	ra,0x1
    8000383c:	078080e7          	jalr	120(ra) # 800048b0 <log_write>
  brelse(bp);
    80003840:	854a                	mv	a0,s2
    80003842:	00000097          	auipc	ra,0x0
    80003846:	dea080e7          	jalr	-534(ra) # 8000362c <brelse>
}
    8000384a:	8526                	mv	a0,s1
    8000384c:	60e6                	ld	ra,88(sp)
    8000384e:	6446                	ld	s0,80(sp)
    80003850:	64a6                	ld	s1,72(sp)
    80003852:	6906                	ld	s2,64(sp)
    80003854:	79e2                	ld	s3,56(sp)
    80003856:	7a42                	ld	s4,48(sp)
    80003858:	7aa2                	ld	s5,40(sp)
    8000385a:	7b02                	ld	s6,32(sp)
    8000385c:	6be2                	ld	s7,24(sp)
    8000385e:	6c42                	ld	s8,16(sp)
    80003860:	6ca2                	ld	s9,8(sp)
    80003862:	6125                	addi	sp,sp,96
    80003864:	8082                	ret
    brelse(bp);
    80003866:	854a                	mv	a0,s2
    80003868:	00000097          	auipc	ra,0x0
    8000386c:	dc4080e7          	jalr	-572(ra) # 8000362c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003870:	015c87bb          	addw	a5,s9,s5
    80003874:	00078a9b          	sext.w	s5,a5
    80003878:	004b2703          	lw	a4,4(s6)
    8000387c:	06eaf363          	bgeu	s5,a4,800038e2 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003880:	41fad79b          	sraiw	a5,s5,0x1f
    80003884:	0137d79b          	srliw	a5,a5,0x13
    80003888:	015787bb          	addw	a5,a5,s5
    8000388c:	40d7d79b          	sraiw	a5,a5,0xd
    80003890:	01cb2583          	lw	a1,28(s6)
    80003894:	9dbd                	addw	a1,a1,a5
    80003896:	855e                	mv	a0,s7
    80003898:	00000097          	auipc	ra,0x0
    8000389c:	c64080e7          	jalr	-924(ra) # 800034fc <bread>
    800038a0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038a2:	004b2503          	lw	a0,4(s6)
    800038a6:	000a849b          	sext.w	s1,s5
    800038aa:	8662                	mv	a2,s8
    800038ac:	faa4fde3          	bgeu	s1,a0,80003866 <balloc+0xa8>
      m = 1 << (bi % 8);
    800038b0:	41f6579b          	sraiw	a5,a2,0x1f
    800038b4:	01d7d69b          	srliw	a3,a5,0x1d
    800038b8:	00c6873b          	addw	a4,a3,a2
    800038bc:	00777793          	andi	a5,a4,7
    800038c0:	9f95                	subw	a5,a5,a3
    800038c2:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800038c6:	4037571b          	sraiw	a4,a4,0x3
    800038ca:	00e906b3          	add	a3,s2,a4
    800038ce:	0586c683          	lbu	a3,88(a3)
    800038d2:	00d7f5b3          	and	a1,a5,a3
    800038d6:	d195                	beqz	a1,800037fa <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038d8:	2605                	addiw	a2,a2,1
    800038da:	2485                	addiw	s1,s1,1
    800038dc:	fd4618e3          	bne	a2,s4,800038ac <balloc+0xee>
    800038e0:	b759                	j	80003866 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800038e2:	00005517          	auipc	a0,0x5
    800038e6:	c9650513          	addi	a0,a0,-874 # 80008578 <syscalls+0x128>
    800038ea:	ffffd097          	auipc	ra,0xffffd
    800038ee:	c9e080e7          	jalr	-866(ra) # 80000588 <printf>
  return 0;
    800038f2:	4481                	li	s1,0
    800038f4:	bf99                	j	8000384a <balloc+0x8c>

00000000800038f6 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800038f6:	7179                	addi	sp,sp,-48
    800038f8:	f406                	sd	ra,40(sp)
    800038fa:	f022                	sd	s0,32(sp)
    800038fc:	ec26                	sd	s1,24(sp)
    800038fe:	e84a                	sd	s2,16(sp)
    80003900:	e44e                	sd	s3,8(sp)
    80003902:	e052                	sd	s4,0(sp)
    80003904:	1800                	addi	s0,sp,48
    80003906:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003908:	47ad                	li	a5,11
    8000390a:	02b7e763          	bltu	a5,a1,80003938 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    8000390e:	02059493          	slli	s1,a1,0x20
    80003912:	9081                	srli	s1,s1,0x20
    80003914:	048a                	slli	s1,s1,0x2
    80003916:	94aa                	add	s1,s1,a0
    80003918:	0504a903          	lw	s2,80(s1)
    8000391c:	06091e63          	bnez	s2,80003998 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003920:	4108                	lw	a0,0(a0)
    80003922:	00000097          	auipc	ra,0x0
    80003926:	e9c080e7          	jalr	-356(ra) # 800037be <balloc>
    8000392a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000392e:	06090563          	beqz	s2,80003998 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003932:	0524a823          	sw	s2,80(s1)
    80003936:	a08d                	j	80003998 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003938:	ff45849b          	addiw	s1,a1,-12
    8000393c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003940:	0ff00793          	li	a5,255
    80003944:	08e7e563          	bltu	a5,a4,800039ce <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003948:	08052903          	lw	s2,128(a0)
    8000394c:	00091d63          	bnez	s2,80003966 <bmap+0x70>
      addr = balloc(ip->dev);
    80003950:	4108                	lw	a0,0(a0)
    80003952:	00000097          	auipc	ra,0x0
    80003956:	e6c080e7          	jalr	-404(ra) # 800037be <balloc>
    8000395a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000395e:	02090d63          	beqz	s2,80003998 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003962:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003966:	85ca                	mv	a1,s2
    80003968:	0009a503          	lw	a0,0(s3)
    8000396c:	00000097          	auipc	ra,0x0
    80003970:	b90080e7          	jalr	-1136(ra) # 800034fc <bread>
    80003974:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003976:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000397a:	02049593          	slli	a1,s1,0x20
    8000397e:	9181                	srli	a1,a1,0x20
    80003980:	058a                	slli	a1,a1,0x2
    80003982:	00b784b3          	add	s1,a5,a1
    80003986:	0004a903          	lw	s2,0(s1)
    8000398a:	02090063          	beqz	s2,800039aa <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000398e:	8552                	mv	a0,s4
    80003990:	00000097          	auipc	ra,0x0
    80003994:	c9c080e7          	jalr	-868(ra) # 8000362c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003998:	854a                	mv	a0,s2
    8000399a:	70a2                	ld	ra,40(sp)
    8000399c:	7402                	ld	s0,32(sp)
    8000399e:	64e2                	ld	s1,24(sp)
    800039a0:	6942                	ld	s2,16(sp)
    800039a2:	69a2                	ld	s3,8(sp)
    800039a4:	6a02                	ld	s4,0(sp)
    800039a6:	6145                	addi	sp,sp,48
    800039a8:	8082                	ret
      addr = balloc(ip->dev);
    800039aa:	0009a503          	lw	a0,0(s3)
    800039ae:	00000097          	auipc	ra,0x0
    800039b2:	e10080e7          	jalr	-496(ra) # 800037be <balloc>
    800039b6:	0005091b          	sext.w	s2,a0
      if(addr){
    800039ba:	fc090ae3          	beqz	s2,8000398e <bmap+0x98>
        a[bn] = addr;
    800039be:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800039c2:	8552                	mv	a0,s4
    800039c4:	00001097          	auipc	ra,0x1
    800039c8:	eec080e7          	jalr	-276(ra) # 800048b0 <log_write>
    800039cc:	b7c9                	j	8000398e <bmap+0x98>
  panic("bmap: out of range");
    800039ce:	00005517          	auipc	a0,0x5
    800039d2:	bc250513          	addi	a0,a0,-1086 # 80008590 <syscalls+0x140>
    800039d6:	ffffd097          	auipc	ra,0xffffd
    800039da:	b68080e7          	jalr	-1176(ra) # 8000053e <panic>

00000000800039de <iget>:
{
    800039de:	7179                	addi	sp,sp,-48
    800039e0:	f406                	sd	ra,40(sp)
    800039e2:	f022                	sd	s0,32(sp)
    800039e4:	ec26                	sd	s1,24(sp)
    800039e6:	e84a                	sd	s2,16(sp)
    800039e8:	e44e                	sd	s3,8(sp)
    800039ea:	e052                	sd	s4,0(sp)
    800039ec:	1800                	addi	s0,sp,48
    800039ee:	89aa                	mv	s3,a0
    800039f0:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800039f2:	0001d517          	auipc	a0,0x1d
    800039f6:	8b650513          	addi	a0,a0,-1866 # 800202a8 <itable>
    800039fa:	ffffd097          	auipc	ra,0xffffd
    800039fe:	1dc080e7          	jalr	476(ra) # 80000bd6 <acquire>
  empty = 0;
    80003a02:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a04:	0001d497          	auipc	s1,0x1d
    80003a08:	8bc48493          	addi	s1,s1,-1860 # 800202c0 <itable+0x18>
    80003a0c:	0001e697          	auipc	a3,0x1e
    80003a10:	34468693          	addi	a3,a3,836 # 80021d50 <log>
    80003a14:	a039                	j	80003a22 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a16:	02090b63          	beqz	s2,80003a4c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a1a:	08848493          	addi	s1,s1,136
    80003a1e:	02d48a63          	beq	s1,a3,80003a52 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a22:	449c                	lw	a5,8(s1)
    80003a24:	fef059e3          	blez	a5,80003a16 <iget+0x38>
    80003a28:	4098                	lw	a4,0(s1)
    80003a2a:	ff3716e3          	bne	a4,s3,80003a16 <iget+0x38>
    80003a2e:	40d8                	lw	a4,4(s1)
    80003a30:	ff4713e3          	bne	a4,s4,80003a16 <iget+0x38>
      ip->ref++;
    80003a34:	2785                	addiw	a5,a5,1
    80003a36:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a38:	0001d517          	auipc	a0,0x1d
    80003a3c:	87050513          	addi	a0,a0,-1936 # 800202a8 <itable>
    80003a40:	ffffd097          	auipc	ra,0xffffd
    80003a44:	24a080e7          	jalr	586(ra) # 80000c8a <release>
      return ip;
    80003a48:	8926                	mv	s2,s1
    80003a4a:	a03d                	j	80003a78 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a4c:	f7f9                	bnez	a5,80003a1a <iget+0x3c>
    80003a4e:	8926                	mv	s2,s1
    80003a50:	b7e9                	j	80003a1a <iget+0x3c>
  if(empty == 0)
    80003a52:	02090c63          	beqz	s2,80003a8a <iget+0xac>
  ip->dev = dev;
    80003a56:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a5a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a5e:	4785                	li	a5,1
    80003a60:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a64:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a68:	0001d517          	auipc	a0,0x1d
    80003a6c:	84050513          	addi	a0,a0,-1984 # 800202a8 <itable>
    80003a70:	ffffd097          	auipc	ra,0xffffd
    80003a74:	21a080e7          	jalr	538(ra) # 80000c8a <release>
}
    80003a78:	854a                	mv	a0,s2
    80003a7a:	70a2                	ld	ra,40(sp)
    80003a7c:	7402                	ld	s0,32(sp)
    80003a7e:	64e2                	ld	s1,24(sp)
    80003a80:	6942                	ld	s2,16(sp)
    80003a82:	69a2                	ld	s3,8(sp)
    80003a84:	6a02                	ld	s4,0(sp)
    80003a86:	6145                	addi	sp,sp,48
    80003a88:	8082                	ret
    panic("iget: no inodes");
    80003a8a:	00005517          	auipc	a0,0x5
    80003a8e:	b1e50513          	addi	a0,a0,-1250 # 800085a8 <syscalls+0x158>
    80003a92:	ffffd097          	auipc	ra,0xffffd
    80003a96:	aac080e7          	jalr	-1364(ra) # 8000053e <panic>

0000000080003a9a <fsinit>:
fsinit(int dev) {
    80003a9a:	7179                	addi	sp,sp,-48
    80003a9c:	f406                	sd	ra,40(sp)
    80003a9e:	f022                	sd	s0,32(sp)
    80003aa0:	ec26                	sd	s1,24(sp)
    80003aa2:	e84a                	sd	s2,16(sp)
    80003aa4:	e44e                	sd	s3,8(sp)
    80003aa6:	1800                	addi	s0,sp,48
    80003aa8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003aaa:	4585                	li	a1,1
    80003aac:	00000097          	auipc	ra,0x0
    80003ab0:	a50080e7          	jalr	-1456(ra) # 800034fc <bread>
    80003ab4:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003ab6:	0001c997          	auipc	s3,0x1c
    80003aba:	7d298993          	addi	s3,s3,2002 # 80020288 <sb>
    80003abe:	02000613          	li	a2,32
    80003ac2:	05850593          	addi	a1,a0,88
    80003ac6:	854e                	mv	a0,s3
    80003ac8:	ffffd097          	auipc	ra,0xffffd
    80003acc:	266080e7          	jalr	614(ra) # 80000d2e <memmove>
  brelse(bp);
    80003ad0:	8526                	mv	a0,s1
    80003ad2:	00000097          	auipc	ra,0x0
    80003ad6:	b5a080e7          	jalr	-1190(ra) # 8000362c <brelse>
  if(sb.magic != FSMAGIC)
    80003ada:	0009a703          	lw	a4,0(s3)
    80003ade:	102037b7          	lui	a5,0x10203
    80003ae2:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ae6:	02f71263          	bne	a4,a5,80003b0a <fsinit+0x70>
  initlog(dev, &sb);
    80003aea:	0001c597          	auipc	a1,0x1c
    80003aee:	79e58593          	addi	a1,a1,1950 # 80020288 <sb>
    80003af2:	854a                	mv	a0,s2
    80003af4:	00001097          	auipc	ra,0x1
    80003af8:	b40080e7          	jalr	-1216(ra) # 80004634 <initlog>
}
    80003afc:	70a2                	ld	ra,40(sp)
    80003afe:	7402                	ld	s0,32(sp)
    80003b00:	64e2                	ld	s1,24(sp)
    80003b02:	6942                	ld	s2,16(sp)
    80003b04:	69a2                	ld	s3,8(sp)
    80003b06:	6145                	addi	sp,sp,48
    80003b08:	8082                	ret
    panic("invalid file system");
    80003b0a:	00005517          	auipc	a0,0x5
    80003b0e:	aae50513          	addi	a0,a0,-1362 # 800085b8 <syscalls+0x168>
    80003b12:	ffffd097          	auipc	ra,0xffffd
    80003b16:	a2c080e7          	jalr	-1492(ra) # 8000053e <panic>

0000000080003b1a <iinit>:
{
    80003b1a:	7179                	addi	sp,sp,-48
    80003b1c:	f406                	sd	ra,40(sp)
    80003b1e:	f022                	sd	s0,32(sp)
    80003b20:	ec26                	sd	s1,24(sp)
    80003b22:	e84a                	sd	s2,16(sp)
    80003b24:	e44e                	sd	s3,8(sp)
    80003b26:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b28:	00005597          	auipc	a1,0x5
    80003b2c:	aa858593          	addi	a1,a1,-1368 # 800085d0 <syscalls+0x180>
    80003b30:	0001c517          	auipc	a0,0x1c
    80003b34:	77850513          	addi	a0,a0,1912 # 800202a8 <itable>
    80003b38:	ffffd097          	auipc	ra,0xffffd
    80003b3c:	00e080e7          	jalr	14(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b40:	0001c497          	auipc	s1,0x1c
    80003b44:	79048493          	addi	s1,s1,1936 # 800202d0 <itable+0x28>
    80003b48:	0001e997          	auipc	s3,0x1e
    80003b4c:	21898993          	addi	s3,s3,536 # 80021d60 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b50:	00005917          	auipc	s2,0x5
    80003b54:	a8890913          	addi	s2,s2,-1400 # 800085d8 <syscalls+0x188>
    80003b58:	85ca                	mv	a1,s2
    80003b5a:	8526                	mv	a0,s1
    80003b5c:	00001097          	auipc	ra,0x1
    80003b60:	e3a080e7          	jalr	-454(ra) # 80004996 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b64:	08848493          	addi	s1,s1,136
    80003b68:	ff3498e3          	bne	s1,s3,80003b58 <iinit+0x3e>
}
    80003b6c:	70a2                	ld	ra,40(sp)
    80003b6e:	7402                	ld	s0,32(sp)
    80003b70:	64e2                	ld	s1,24(sp)
    80003b72:	6942                	ld	s2,16(sp)
    80003b74:	69a2                	ld	s3,8(sp)
    80003b76:	6145                	addi	sp,sp,48
    80003b78:	8082                	ret

0000000080003b7a <ialloc>:
{
    80003b7a:	715d                	addi	sp,sp,-80
    80003b7c:	e486                	sd	ra,72(sp)
    80003b7e:	e0a2                	sd	s0,64(sp)
    80003b80:	fc26                	sd	s1,56(sp)
    80003b82:	f84a                	sd	s2,48(sp)
    80003b84:	f44e                	sd	s3,40(sp)
    80003b86:	f052                	sd	s4,32(sp)
    80003b88:	ec56                	sd	s5,24(sp)
    80003b8a:	e85a                	sd	s6,16(sp)
    80003b8c:	e45e                	sd	s7,8(sp)
    80003b8e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b90:	0001c717          	auipc	a4,0x1c
    80003b94:	70472703          	lw	a4,1796(a4) # 80020294 <sb+0xc>
    80003b98:	4785                	li	a5,1
    80003b9a:	04e7fa63          	bgeu	a5,a4,80003bee <ialloc+0x74>
    80003b9e:	8aaa                	mv	s5,a0
    80003ba0:	8bae                	mv	s7,a1
    80003ba2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003ba4:	0001ca17          	auipc	s4,0x1c
    80003ba8:	6e4a0a13          	addi	s4,s4,1764 # 80020288 <sb>
    80003bac:	00048b1b          	sext.w	s6,s1
    80003bb0:	0044d793          	srli	a5,s1,0x4
    80003bb4:	018a2583          	lw	a1,24(s4)
    80003bb8:	9dbd                	addw	a1,a1,a5
    80003bba:	8556                	mv	a0,s5
    80003bbc:	00000097          	auipc	ra,0x0
    80003bc0:	940080e7          	jalr	-1728(ra) # 800034fc <bread>
    80003bc4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003bc6:	05850993          	addi	s3,a0,88
    80003bca:	00f4f793          	andi	a5,s1,15
    80003bce:	079a                	slli	a5,a5,0x6
    80003bd0:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003bd2:	00099783          	lh	a5,0(s3)
    80003bd6:	c3a1                	beqz	a5,80003c16 <ialloc+0x9c>
    brelse(bp);
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	a54080e7          	jalr	-1452(ra) # 8000362c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003be0:	0485                	addi	s1,s1,1
    80003be2:	00ca2703          	lw	a4,12(s4)
    80003be6:	0004879b          	sext.w	a5,s1
    80003bea:	fce7e1e3          	bltu	a5,a4,80003bac <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003bee:	00005517          	auipc	a0,0x5
    80003bf2:	9f250513          	addi	a0,a0,-1550 # 800085e0 <syscalls+0x190>
    80003bf6:	ffffd097          	auipc	ra,0xffffd
    80003bfa:	992080e7          	jalr	-1646(ra) # 80000588 <printf>
  return 0;
    80003bfe:	4501                	li	a0,0
}
    80003c00:	60a6                	ld	ra,72(sp)
    80003c02:	6406                	ld	s0,64(sp)
    80003c04:	74e2                	ld	s1,56(sp)
    80003c06:	7942                	ld	s2,48(sp)
    80003c08:	79a2                	ld	s3,40(sp)
    80003c0a:	7a02                	ld	s4,32(sp)
    80003c0c:	6ae2                	ld	s5,24(sp)
    80003c0e:	6b42                	ld	s6,16(sp)
    80003c10:	6ba2                	ld	s7,8(sp)
    80003c12:	6161                	addi	sp,sp,80
    80003c14:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003c16:	04000613          	li	a2,64
    80003c1a:	4581                	li	a1,0
    80003c1c:	854e                	mv	a0,s3
    80003c1e:	ffffd097          	auipc	ra,0xffffd
    80003c22:	0b4080e7          	jalr	180(ra) # 80000cd2 <memset>
      dip->type = type;
    80003c26:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c2a:	854a                	mv	a0,s2
    80003c2c:	00001097          	auipc	ra,0x1
    80003c30:	c84080e7          	jalr	-892(ra) # 800048b0 <log_write>
      brelse(bp);
    80003c34:	854a                	mv	a0,s2
    80003c36:	00000097          	auipc	ra,0x0
    80003c3a:	9f6080e7          	jalr	-1546(ra) # 8000362c <brelse>
      return iget(dev, inum);
    80003c3e:	85da                	mv	a1,s6
    80003c40:	8556                	mv	a0,s5
    80003c42:	00000097          	auipc	ra,0x0
    80003c46:	d9c080e7          	jalr	-612(ra) # 800039de <iget>
    80003c4a:	bf5d                	j	80003c00 <ialloc+0x86>

0000000080003c4c <iupdate>:
{
    80003c4c:	1101                	addi	sp,sp,-32
    80003c4e:	ec06                	sd	ra,24(sp)
    80003c50:	e822                	sd	s0,16(sp)
    80003c52:	e426                	sd	s1,8(sp)
    80003c54:	e04a                	sd	s2,0(sp)
    80003c56:	1000                	addi	s0,sp,32
    80003c58:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c5a:	415c                	lw	a5,4(a0)
    80003c5c:	0047d79b          	srliw	a5,a5,0x4
    80003c60:	0001c597          	auipc	a1,0x1c
    80003c64:	6405a583          	lw	a1,1600(a1) # 800202a0 <sb+0x18>
    80003c68:	9dbd                	addw	a1,a1,a5
    80003c6a:	4108                	lw	a0,0(a0)
    80003c6c:	00000097          	auipc	ra,0x0
    80003c70:	890080e7          	jalr	-1904(ra) # 800034fc <bread>
    80003c74:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c76:	05850793          	addi	a5,a0,88
    80003c7a:	40c8                	lw	a0,4(s1)
    80003c7c:	893d                	andi	a0,a0,15
    80003c7e:	051a                	slli	a0,a0,0x6
    80003c80:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c82:	04449703          	lh	a4,68(s1)
    80003c86:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003c8a:	04649703          	lh	a4,70(s1)
    80003c8e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003c92:	04849703          	lh	a4,72(s1)
    80003c96:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003c9a:	04a49703          	lh	a4,74(s1)
    80003c9e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003ca2:	44f8                	lw	a4,76(s1)
    80003ca4:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003ca6:	03400613          	li	a2,52
    80003caa:	05048593          	addi	a1,s1,80
    80003cae:	0531                	addi	a0,a0,12
    80003cb0:	ffffd097          	auipc	ra,0xffffd
    80003cb4:	07e080e7          	jalr	126(ra) # 80000d2e <memmove>
  log_write(bp);
    80003cb8:	854a                	mv	a0,s2
    80003cba:	00001097          	auipc	ra,0x1
    80003cbe:	bf6080e7          	jalr	-1034(ra) # 800048b0 <log_write>
  brelse(bp);
    80003cc2:	854a                	mv	a0,s2
    80003cc4:	00000097          	auipc	ra,0x0
    80003cc8:	968080e7          	jalr	-1688(ra) # 8000362c <brelse>
}
    80003ccc:	60e2                	ld	ra,24(sp)
    80003cce:	6442                	ld	s0,16(sp)
    80003cd0:	64a2                	ld	s1,8(sp)
    80003cd2:	6902                	ld	s2,0(sp)
    80003cd4:	6105                	addi	sp,sp,32
    80003cd6:	8082                	ret

0000000080003cd8 <idup>:
{
    80003cd8:	1101                	addi	sp,sp,-32
    80003cda:	ec06                	sd	ra,24(sp)
    80003cdc:	e822                	sd	s0,16(sp)
    80003cde:	e426                	sd	s1,8(sp)
    80003ce0:	1000                	addi	s0,sp,32
    80003ce2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ce4:	0001c517          	auipc	a0,0x1c
    80003ce8:	5c450513          	addi	a0,a0,1476 # 800202a8 <itable>
    80003cec:	ffffd097          	auipc	ra,0xffffd
    80003cf0:	eea080e7          	jalr	-278(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003cf4:	449c                	lw	a5,8(s1)
    80003cf6:	2785                	addiw	a5,a5,1
    80003cf8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cfa:	0001c517          	auipc	a0,0x1c
    80003cfe:	5ae50513          	addi	a0,a0,1454 # 800202a8 <itable>
    80003d02:	ffffd097          	auipc	ra,0xffffd
    80003d06:	f88080e7          	jalr	-120(ra) # 80000c8a <release>
}
    80003d0a:	8526                	mv	a0,s1
    80003d0c:	60e2                	ld	ra,24(sp)
    80003d0e:	6442                	ld	s0,16(sp)
    80003d10:	64a2                	ld	s1,8(sp)
    80003d12:	6105                	addi	sp,sp,32
    80003d14:	8082                	ret

0000000080003d16 <ilock>:
{
    80003d16:	1101                	addi	sp,sp,-32
    80003d18:	ec06                	sd	ra,24(sp)
    80003d1a:	e822                	sd	s0,16(sp)
    80003d1c:	e426                	sd	s1,8(sp)
    80003d1e:	e04a                	sd	s2,0(sp)
    80003d20:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d22:	c115                	beqz	a0,80003d46 <ilock+0x30>
    80003d24:	84aa                	mv	s1,a0
    80003d26:	451c                	lw	a5,8(a0)
    80003d28:	00f05f63          	blez	a5,80003d46 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d2c:	0541                	addi	a0,a0,16
    80003d2e:	00001097          	auipc	ra,0x1
    80003d32:	ca2080e7          	jalr	-862(ra) # 800049d0 <acquiresleep>
  if(ip->valid == 0){
    80003d36:	40bc                	lw	a5,64(s1)
    80003d38:	cf99                	beqz	a5,80003d56 <ilock+0x40>
}
    80003d3a:	60e2                	ld	ra,24(sp)
    80003d3c:	6442                	ld	s0,16(sp)
    80003d3e:	64a2                	ld	s1,8(sp)
    80003d40:	6902                	ld	s2,0(sp)
    80003d42:	6105                	addi	sp,sp,32
    80003d44:	8082                	ret
    panic("ilock");
    80003d46:	00005517          	auipc	a0,0x5
    80003d4a:	8b250513          	addi	a0,a0,-1870 # 800085f8 <syscalls+0x1a8>
    80003d4e:	ffffc097          	auipc	ra,0xffffc
    80003d52:	7f0080e7          	jalr	2032(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d56:	40dc                	lw	a5,4(s1)
    80003d58:	0047d79b          	srliw	a5,a5,0x4
    80003d5c:	0001c597          	auipc	a1,0x1c
    80003d60:	5445a583          	lw	a1,1348(a1) # 800202a0 <sb+0x18>
    80003d64:	9dbd                	addw	a1,a1,a5
    80003d66:	4088                	lw	a0,0(s1)
    80003d68:	fffff097          	auipc	ra,0xfffff
    80003d6c:	794080e7          	jalr	1940(ra) # 800034fc <bread>
    80003d70:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d72:	05850593          	addi	a1,a0,88
    80003d76:	40dc                	lw	a5,4(s1)
    80003d78:	8bbd                	andi	a5,a5,15
    80003d7a:	079a                	slli	a5,a5,0x6
    80003d7c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d7e:	00059783          	lh	a5,0(a1)
    80003d82:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d86:	00259783          	lh	a5,2(a1)
    80003d8a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d8e:	00459783          	lh	a5,4(a1)
    80003d92:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d96:	00659783          	lh	a5,6(a1)
    80003d9a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d9e:	459c                	lw	a5,8(a1)
    80003da0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003da2:	03400613          	li	a2,52
    80003da6:	05b1                	addi	a1,a1,12
    80003da8:	05048513          	addi	a0,s1,80
    80003dac:	ffffd097          	auipc	ra,0xffffd
    80003db0:	f82080e7          	jalr	-126(ra) # 80000d2e <memmove>
    brelse(bp);
    80003db4:	854a                	mv	a0,s2
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	876080e7          	jalr	-1930(ra) # 8000362c <brelse>
    ip->valid = 1;
    80003dbe:	4785                	li	a5,1
    80003dc0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003dc2:	04449783          	lh	a5,68(s1)
    80003dc6:	fbb5                	bnez	a5,80003d3a <ilock+0x24>
      panic("ilock: no type");
    80003dc8:	00005517          	auipc	a0,0x5
    80003dcc:	83850513          	addi	a0,a0,-1992 # 80008600 <syscalls+0x1b0>
    80003dd0:	ffffc097          	auipc	ra,0xffffc
    80003dd4:	76e080e7          	jalr	1902(ra) # 8000053e <panic>

0000000080003dd8 <iunlock>:
{
    80003dd8:	1101                	addi	sp,sp,-32
    80003dda:	ec06                	sd	ra,24(sp)
    80003ddc:	e822                	sd	s0,16(sp)
    80003dde:	e426                	sd	s1,8(sp)
    80003de0:	e04a                	sd	s2,0(sp)
    80003de2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003de4:	c905                	beqz	a0,80003e14 <iunlock+0x3c>
    80003de6:	84aa                	mv	s1,a0
    80003de8:	01050913          	addi	s2,a0,16
    80003dec:	854a                	mv	a0,s2
    80003dee:	00001097          	auipc	ra,0x1
    80003df2:	c7c080e7          	jalr	-900(ra) # 80004a6a <holdingsleep>
    80003df6:	cd19                	beqz	a0,80003e14 <iunlock+0x3c>
    80003df8:	449c                	lw	a5,8(s1)
    80003dfa:	00f05d63          	blez	a5,80003e14 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003dfe:	854a                	mv	a0,s2
    80003e00:	00001097          	auipc	ra,0x1
    80003e04:	c26080e7          	jalr	-986(ra) # 80004a26 <releasesleep>
}
    80003e08:	60e2                	ld	ra,24(sp)
    80003e0a:	6442                	ld	s0,16(sp)
    80003e0c:	64a2                	ld	s1,8(sp)
    80003e0e:	6902                	ld	s2,0(sp)
    80003e10:	6105                	addi	sp,sp,32
    80003e12:	8082                	ret
    panic("iunlock");
    80003e14:	00004517          	auipc	a0,0x4
    80003e18:	7fc50513          	addi	a0,a0,2044 # 80008610 <syscalls+0x1c0>
    80003e1c:	ffffc097          	auipc	ra,0xffffc
    80003e20:	722080e7          	jalr	1826(ra) # 8000053e <panic>

0000000080003e24 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e24:	7179                	addi	sp,sp,-48
    80003e26:	f406                	sd	ra,40(sp)
    80003e28:	f022                	sd	s0,32(sp)
    80003e2a:	ec26                	sd	s1,24(sp)
    80003e2c:	e84a                	sd	s2,16(sp)
    80003e2e:	e44e                	sd	s3,8(sp)
    80003e30:	e052                	sd	s4,0(sp)
    80003e32:	1800                	addi	s0,sp,48
    80003e34:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e36:	05050493          	addi	s1,a0,80
    80003e3a:	08050913          	addi	s2,a0,128
    80003e3e:	a021                	j	80003e46 <itrunc+0x22>
    80003e40:	0491                	addi	s1,s1,4
    80003e42:	01248d63          	beq	s1,s2,80003e5c <itrunc+0x38>
    if(ip->addrs[i]){
    80003e46:	408c                	lw	a1,0(s1)
    80003e48:	dde5                	beqz	a1,80003e40 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e4a:	0009a503          	lw	a0,0(s3)
    80003e4e:	00000097          	auipc	ra,0x0
    80003e52:	8f4080e7          	jalr	-1804(ra) # 80003742 <bfree>
      ip->addrs[i] = 0;
    80003e56:	0004a023          	sw	zero,0(s1)
    80003e5a:	b7dd                	j	80003e40 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e5c:	0809a583          	lw	a1,128(s3)
    80003e60:	e185                	bnez	a1,80003e80 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e62:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e66:	854e                	mv	a0,s3
    80003e68:	00000097          	auipc	ra,0x0
    80003e6c:	de4080e7          	jalr	-540(ra) # 80003c4c <iupdate>
}
    80003e70:	70a2                	ld	ra,40(sp)
    80003e72:	7402                	ld	s0,32(sp)
    80003e74:	64e2                	ld	s1,24(sp)
    80003e76:	6942                	ld	s2,16(sp)
    80003e78:	69a2                	ld	s3,8(sp)
    80003e7a:	6a02                	ld	s4,0(sp)
    80003e7c:	6145                	addi	sp,sp,48
    80003e7e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e80:	0009a503          	lw	a0,0(s3)
    80003e84:	fffff097          	auipc	ra,0xfffff
    80003e88:	678080e7          	jalr	1656(ra) # 800034fc <bread>
    80003e8c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e8e:	05850493          	addi	s1,a0,88
    80003e92:	45850913          	addi	s2,a0,1112
    80003e96:	a021                	j	80003e9e <itrunc+0x7a>
    80003e98:	0491                	addi	s1,s1,4
    80003e9a:	01248b63          	beq	s1,s2,80003eb0 <itrunc+0x8c>
      if(a[j])
    80003e9e:	408c                	lw	a1,0(s1)
    80003ea0:	dde5                	beqz	a1,80003e98 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003ea2:	0009a503          	lw	a0,0(s3)
    80003ea6:	00000097          	auipc	ra,0x0
    80003eaa:	89c080e7          	jalr	-1892(ra) # 80003742 <bfree>
    80003eae:	b7ed                	j	80003e98 <itrunc+0x74>
    brelse(bp);
    80003eb0:	8552                	mv	a0,s4
    80003eb2:	fffff097          	auipc	ra,0xfffff
    80003eb6:	77a080e7          	jalr	1914(ra) # 8000362c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003eba:	0809a583          	lw	a1,128(s3)
    80003ebe:	0009a503          	lw	a0,0(s3)
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	880080e7          	jalr	-1920(ra) # 80003742 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003eca:	0809a023          	sw	zero,128(s3)
    80003ece:	bf51                	j	80003e62 <itrunc+0x3e>

0000000080003ed0 <iput>:
{
    80003ed0:	1101                	addi	sp,sp,-32
    80003ed2:	ec06                	sd	ra,24(sp)
    80003ed4:	e822                	sd	s0,16(sp)
    80003ed6:	e426                	sd	s1,8(sp)
    80003ed8:	e04a                	sd	s2,0(sp)
    80003eda:	1000                	addi	s0,sp,32
    80003edc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ede:	0001c517          	auipc	a0,0x1c
    80003ee2:	3ca50513          	addi	a0,a0,970 # 800202a8 <itable>
    80003ee6:	ffffd097          	auipc	ra,0xffffd
    80003eea:	cf0080e7          	jalr	-784(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003eee:	4498                	lw	a4,8(s1)
    80003ef0:	4785                	li	a5,1
    80003ef2:	02f70363          	beq	a4,a5,80003f18 <iput+0x48>
  ip->ref--;
    80003ef6:	449c                	lw	a5,8(s1)
    80003ef8:	37fd                	addiw	a5,a5,-1
    80003efa:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003efc:	0001c517          	auipc	a0,0x1c
    80003f00:	3ac50513          	addi	a0,a0,940 # 800202a8 <itable>
    80003f04:	ffffd097          	auipc	ra,0xffffd
    80003f08:	d86080e7          	jalr	-634(ra) # 80000c8a <release>
}
    80003f0c:	60e2                	ld	ra,24(sp)
    80003f0e:	6442                	ld	s0,16(sp)
    80003f10:	64a2                	ld	s1,8(sp)
    80003f12:	6902                	ld	s2,0(sp)
    80003f14:	6105                	addi	sp,sp,32
    80003f16:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f18:	40bc                	lw	a5,64(s1)
    80003f1a:	dff1                	beqz	a5,80003ef6 <iput+0x26>
    80003f1c:	04a49783          	lh	a5,74(s1)
    80003f20:	fbf9                	bnez	a5,80003ef6 <iput+0x26>
    acquiresleep(&ip->lock);
    80003f22:	01048913          	addi	s2,s1,16
    80003f26:	854a                	mv	a0,s2
    80003f28:	00001097          	auipc	ra,0x1
    80003f2c:	aa8080e7          	jalr	-1368(ra) # 800049d0 <acquiresleep>
    release(&itable.lock);
    80003f30:	0001c517          	auipc	a0,0x1c
    80003f34:	37850513          	addi	a0,a0,888 # 800202a8 <itable>
    80003f38:	ffffd097          	auipc	ra,0xffffd
    80003f3c:	d52080e7          	jalr	-686(ra) # 80000c8a <release>
    itrunc(ip);
    80003f40:	8526                	mv	a0,s1
    80003f42:	00000097          	auipc	ra,0x0
    80003f46:	ee2080e7          	jalr	-286(ra) # 80003e24 <itrunc>
    ip->type = 0;
    80003f4a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f4e:	8526                	mv	a0,s1
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	cfc080e7          	jalr	-772(ra) # 80003c4c <iupdate>
    ip->valid = 0;
    80003f58:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f5c:	854a                	mv	a0,s2
    80003f5e:	00001097          	auipc	ra,0x1
    80003f62:	ac8080e7          	jalr	-1336(ra) # 80004a26 <releasesleep>
    acquire(&itable.lock);
    80003f66:	0001c517          	auipc	a0,0x1c
    80003f6a:	34250513          	addi	a0,a0,834 # 800202a8 <itable>
    80003f6e:	ffffd097          	auipc	ra,0xffffd
    80003f72:	c68080e7          	jalr	-920(ra) # 80000bd6 <acquire>
    80003f76:	b741                	j	80003ef6 <iput+0x26>

0000000080003f78 <iunlockput>:
{
    80003f78:	1101                	addi	sp,sp,-32
    80003f7a:	ec06                	sd	ra,24(sp)
    80003f7c:	e822                	sd	s0,16(sp)
    80003f7e:	e426                	sd	s1,8(sp)
    80003f80:	1000                	addi	s0,sp,32
    80003f82:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	e54080e7          	jalr	-428(ra) # 80003dd8 <iunlock>
  iput(ip);
    80003f8c:	8526                	mv	a0,s1
    80003f8e:	00000097          	auipc	ra,0x0
    80003f92:	f42080e7          	jalr	-190(ra) # 80003ed0 <iput>
}
    80003f96:	60e2                	ld	ra,24(sp)
    80003f98:	6442                	ld	s0,16(sp)
    80003f9a:	64a2                	ld	s1,8(sp)
    80003f9c:	6105                	addi	sp,sp,32
    80003f9e:	8082                	ret

0000000080003fa0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003fa0:	1141                	addi	sp,sp,-16
    80003fa2:	e422                	sd	s0,8(sp)
    80003fa4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003fa6:	411c                	lw	a5,0(a0)
    80003fa8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003faa:	415c                	lw	a5,4(a0)
    80003fac:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003fae:	04451783          	lh	a5,68(a0)
    80003fb2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003fb6:	04a51783          	lh	a5,74(a0)
    80003fba:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003fbe:	04c56783          	lwu	a5,76(a0)
    80003fc2:	e99c                	sd	a5,16(a1)
}
    80003fc4:	6422                	ld	s0,8(sp)
    80003fc6:	0141                	addi	sp,sp,16
    80003fc8:	8082                	ret

0000000080003fca <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fca:	457c                	lw	a5,76(a0)
    80003fcc:	0ed7e963          	bltu	a5,a3,800040be <readi+0xf4>
{
    80003fd0:	7159                	addi	sp,sp,-112
    80003fd2:	f486                	sd	ra,104(sp)
    80003fd4:	f0a2                	sd	s0,96(sp)
    80003fd6:	eca6                	sd	s1,88(sp)
    80003fd8:	e8ca                	sd	s2,80(sp)
    80003fda:	e4ce                	sd	s3,72(sp)
    80003fdc:	e0d2                	sd	s4,64(sp)
    80003fde:	fc56                	sd	s5,56(sp)
    80003fe0:	f85a                	sd	s6,48(sp)
    80003fe2:	f45e                	sd	s7,40(sp)
    80003fe4:	f062                	sd	s8,32(sp)
    80003fe6:	ec66                	sd	s9,24(sp)
    80003fe8:	e86a                	sd	s10,16(sp)
    80003fea:	e46e                	sd	s11,8(sp)
    80003fec:	1880                	addi	s0,sp,112
    80003fee:	8b2a                	mv	s6,a0
    80003ff0:	8bae                	mv	s7,a1
    80003ff2:	8a32                	mv	s4,a2
    80003ff4:	84b6                	mv	s1,a3
    80003ff6:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003ff8:	9f35                	addw	a4,a4,a3
    return 0;
    80003ffa:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ffc:	0ad76063          	bltu	a4,a3,8000409c <readi+0xd2>
  if(off + n > ip->size)
    80004000:	00e7f463          	bgeu	a5,a4,80004008 <readi+0x3e>
    n = ip->size - off;
    80004004:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004008:	0a0a8963          	beqz	s5,800040ba <readi+0xf0>
    8000400c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000400e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004012:	5c7d                	li	s8,-1
    80004014:	a82d                	j	8000404e <readi+0x84>
    80004016:	020d1d93          	slli	s11,s10,0x20
    8000401a:	020ddd93          	srli	s11,s11,0x20
    8000401e:	05890793          	addi	a5,s2,88
    80004022:	86ee                	mv	a3,s11
    80004024:	963e                	add	a2,a2,a5
    80004026:	85d2                	mv	a1,s4
    80004028:	855e                	mv	a0,s7
    8000402a:	ffffe097          	auipc	ra,0xffffe
    8000402e:	494080e7          	jalr	1172(ra) # 800024be <either_copyout>
    80004032:	05850d63          	beq	a0,s8,8000408c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004036:	854a                	mv	a0,s2
    80004038:	fffff097          	auipc	ra,0xfffff
    8000403c:	5f4080e7          	jalr	1524(ra) # 8000362c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004040:	013d09bb          	addw	s3,s10,s3
    80004044:	009d04bb          	addw	s1,s10,s1
    80004048:	9a6e                	add	s4,s4,s11
    8000404a:	0559f763          	bgeu	s3,s5,80004098 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    8000404e:	00a4d59b          	srliw	a1,s1,0xa
    80004052:	855a                	mv	a0,s6
    80004054:	00000097          	auipc	ra,0x0
    80004058:	8a2080e7          	jalr	-1886(ra) # 800038f6 <bmap>
    8000405c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004060:	cd85                	beqz	a1,80004098 <readi+0xce>
    bp = bread(ip->dev, addr);
    80004062:	000b2503          	lw	a0,0(s6)
    80004066:	fffff097          	auipc	ra,0xfffff
    8000406a:	496080e7          	jalr	1174(ra) # 800034fc <bread>
    8000406e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004070:	3ff4f613          	andi	a2,s1,1023
    80004074:	40cc87bb          	subw	a5,s9,a2
    80004078:	413a873b          	subw	a4,s5,s3
    8000407c:	8d3e                	mv	s10,a5
    8000407e:	2781                	sext.w	a5,a5
    80004080:	0007069b          	sext.w	a3,a4
    80004084:	f8f6f9e3          	bgeu	a3,a5,80004016 <readi+0x4c>
    80004088:	8d3a                	mv	s10,a4
    8000408a:	b771                	j	80004016 <readi+0x4c>
      brelse(bp);
    8000408c:	854a                	mv	a0,s2
    8000408e:	fffff097          	auipc	ra,0xfffff
    80004092:	59e080e7          	jalr	1438(ra) # 8000362c <brelse>
      tot = -1;
    80004096:	59fd                	li	s3,-1
  }
  return tot;
    80004098:	0009851b          	sext.w	a0,s3
}
    8000409c:	70a6                	ld	ra,104(sp)
    8000409e:	7406                	ld	s0,96(sp)
    800040a0:	64e6                	ld	s1,88(sp)
    800040a2:	6946                	ld	s2,80(sp)
    800040a4:	69a6                	ld	s3,72(sp)
    800040a6:	6a06                	ld	s4,64(sp)
    800040a8:	7ae2                	ld	s5,56(sp)
    800040aa:	7b42                	ld	s6,48(sp)
    800040ac:	7ba2                	ld	s7,40(sp)
    800040ae:	7c02                	ld	s8,32(sp)
    800040b0:	6ce2                	ld	s9,24(sp)
    800040b2:	6d42                	ld	s10,16(sp)
    800040b4:	6da2                	ld	s11,8(sp)
    800040b6:	6165                	addi	sp,sp,112
    800040b8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040ba:	89d6                	mv	s3,s5
    800040bc:	bff1                	j	80004098 <readi+0xce>
    return 0;
    800040be:	4501                	li	a0,0
}
    800040c0:	8082                	ret

00000000800040c2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040c2:	457c                	lw	a5,76(a0)
    800040c4:	10d7e863          	bltu	a5,a3,800041d4 <writei+0x112>
{
    800040c8:	7159                	addi	sp,sp,-112
    800040ca:	f486                	sd	ra,104(sp)
    800040cc:	f0a2                	sd	s0,96(sp)
    800040ce:	eca6                	sd	s1,88(sp)
    800040d0:	e8ca                	sd	s2,80(sp)
    800040d2:	e4ce                	sd	s3,72(sp)
    800040d4:	e0d2                	sd	s4,64(sp)
    800040d6:	fc56                	sd	s5,56(sp)
    800040d8:	f85a                	sd	s6,48(sp)
    800040da:	f45e                	sd	s7,40(sp)
    800040dc:	f062                	sd	s8,32(sp)
    800040de:	ec66                	sd	s9,24(sp)
    800040e0:	e86a                	sd	s10,16(sp)
    800040e2:	e46e                	sd	s11,8(sp)
    800040e4:	1880                	addi	s0,sp,112
    800040e6:	8aaa                	mv	s5,a0
    800040e8:	8bae                	mv	s7,a1
    800040ea:	8a32                	mv	s4,a2
    800040ec:	8936                	mv	s2,a3
    800040ee:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040f0:	00e687bb          	addw	a5,a3,a4
    800040f4:	0ed7e263          	bltu	a5,a3,800041d8 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800040f8:	00043737          	lui	a4,0x43
    800040fc:	0ef76063          	bltu	a4,a5,800041dc <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004100:	0c0b0863          	beqz	s6,800041d0 <writei+0x10e>
    80004104:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004106:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000410a:	5c7d                	li	s8,-1
    8000410c:	a091                	j	80004150 <writei+0x8e>
    8000410e:	020d1d93          	slli	s11,s10,0x20
    80004112:	020ddd93          	srli	s11,s11,0x20
    80004116:	05848793          	addi	a5,s1,88
    8000411a:	86ee                	mv	a3,s11
    8000411c:	8652                	mv	a2,s4
    8000411e:	85de                	mv	a1,s7
    80004120:	953e                	add	a0,a0,a5
    80004122:	ffffe097          	auipc	ra,0xffffe
    80004126:	3f2080e7          	jalr	1010(ra) # 80002514 <either_copyin>
    8000412a:	07850263          	beq	a0,s8,8000418e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000412e:	8526                	mv	a0,s1
    80004130:	00000097          	auipc	ra,0x0
    80004134:	780080e7          	jalr	1920(ra) # 800048b0 <log_write>
    brelse(bp);
    80004138:	8526                	mv	a0,s1
    8000413a:	fffff097          	auipc	ra,0xfffff
    8000413e:	4f2080e7          	jalr	1266(ra) # 8000362c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004142:	013d09bb          	addw	s3,s10,s3
    80004146:	012d093b          	addw	s2,s10,s2
    8000414a:	9a6e                	add	s4,s4,s11
    8000414c:	0569f663          	bgeu	s3,s6,80004198 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004150:	00a9559b          	srliw	a1,s2,0xa
    80004154:	8556                	mv	a0,s5
    80004156:	fffff097          	auipc	ra,0xfffff
    8000415a:	7a0080e7          	jalr	1952(ra) # 800038f6 <bmap>
    8000415e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004162:	c99d                	beqz	a1,80004198 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004164:	000aa503          	lw	a0,0(s5)
    80004168:	fffff097          	auipc	ra,0xfffff
    8000416c:	394080e7          	jalr	916(ra) # 800034fc <bread>
    80004170:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004172:	3ff97513          	andi	a0,s2,1023
    80004176:	40ac87bb          	subw	a5,s9,a0
    8000417a:	413b073b          	subw	a4,s6,s3
    8000417e:	8d3e                	mv	s10,a5
    80004180:	2781                	sext.w	a5,a5
    80004182:	0007069b          	sext.w	a3,a4
    80004186:	f8f6f4e3          	bgeu	a3,a5,8000410e <writei+0x4c>
    8000418a:	8d3a                	mv	s10,a4
    8000418c:	b749                	j	8000410e <writei+0x4c>
      brelse(bp);
    8000418e:	8526                	mv	a0,s1
    80004190:	fffff097          	auipc	ra,0xfffff
    80004194:	49c080e7          	jalr	1180(ra) # 8000362c <brelse>
  }

  if(off > ip->size)
    80004198:	04caa783          	lw	a5,76(s5)
    8000419c:	0127f463          	bgeu	a5,s2,800041a4 <writei+0xe2>
    ip->size = off;
    800041a0:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800041a4:	8556                	mv	a0,s5
    800041a6:	00000097          	auipc	ra,0x0
    800041aa:	aa6080e7          	jalr	-1370(ra) # 80003c4c <iupdate>

  return tot;
    800041ae:	0009851b          	sext.w	a0,s3
}
    800041b2:	70a6                	ld	ra,104(sp)
    800041b4:	7406                	ld	s0,96(sp)
    800041b6:	64e6                	ld	s1,88(sp)
    800041b8:	6946                	ld	s2,80(sp)
    800041ba:	69a6                	ld	s3,72(sp)
    800041bc:	6a06                	ld	s4,64(sp)
    800041be:	7ae2                	ld	s5,56(sp)
    800041c0:	7b42                	ld	s6,48(sp)
    800041c2:	7ba2                	ld	s7,40(sp)
    800041c4:	7c02                	ld	s8,32(sp)
    800041c6:	6ce2                	ld	s9,24(sp)
    800041c8:	6d42                	ld	s10,16(sp)
    800041ca:	6da2                	ld	s11,8(sp)
    800041cc:	6165                	addi	sp,sp,112
    800041ce:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041d0:	89da                	mv	s3,s6
    800041d2:	bfc9                	j	800041a4 <writei+0xe2>
    return -1;
    800041d4:	557d                	li	a0,-1
}
    800041d6:	8082                	ret
    return -1;
    800041d8:	557d                	li	a0,-1
    800041da:	bfe1                	j	800041b2 <writei+0xf0>
    return -1;
    800041dc:	557d                	li	a0,-1
    800041de:	bfd1                	j	800041b2 <writei+0xf0>

00000000800041e0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800041e0:	1141                	addi	sp,sp,-16
    800041e2:	e406                	sd	ra,8(sp)
    800041e4:	e022                	sd	s0,0(sp)
    800041e6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800041e8:	4639                	li	a2,14
    800041ea:	ffffd097          	auipc	ra,0xffffd
    800041ee:	bb8080e7          	jalr	-1096(ra) # 80000da2 <strncmp>
}
    800041f2:	60a2                	ld	ra,8(sp)
    800041f4:	6402                	ld	s0,0(sp)
    800041f6:	0141                	addi	sp,sp,16
    800041f8:	8082                	ret

00000000800041fa <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800041fa:	7139                	addi	sp,sp,-64
    800041fc:	fc06                	sd	ra,56(sp)
    800041fe:	f822                	sd	s0,48(sp)
    80004200:	f426                	sd	s1,40(sp)
    80004202:	f04a                	sd	s2,32(sp)
    80004204:	ec4e                	sd	s3,24(sp)
    80004206:	e852                	sd	s4,16(sp)
    80004208:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000420a:	04451703          	lh	a4,68(a0)
    8000420e:	4785                	li	a5,1
    80004210:	00f71a63          	bne	a4,a5,80004224 <dirlookup+0x2a>
    80004214:	892a                	mv	s2,a0
    80004216:	89ae                	mv	s3,a1
    80004218:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000421a:	457c                	lw	a5,76(a0)
    8000421c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000421e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004220:	e79d                	bnez	a5,8000424e <dirlookup+0x54>
    80004222:	a8a5                	j	8000429a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004224:	00004517          	auipc	a0,0x4
    80004228:	3f450513          	addi	a0,a0,1012 # 80008618 <syscalls+0x1c8>
    8000422c:	ffffc097          	auipc	ra,0xffffc
    80004230:	312080e7          	jalr	786(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004234:	00004517          	auipc	a0,0x4
    80004238:	3fc50513          	addi	a0,a0,1020 # 80008630 <syscalls+0x1e0>
    8000423c:	ffffc097          	auipc	ra,0xffffc
    80004240:	302080e7          	jalr	770(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004244:	24c1                	addiw	s1,s1,16
    80004246:	04c92783          	lw	a5,76(s2)
    8000424a:	04f4f763          	bgeu	s1,a5,80004298 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000424e:	4741                	li	a4,16
    80004250:	86a6                	mv	a3,s1
    80004252:	fc040613          	addi	a2,s0,-64
    80004256:	4581                	li	a1,0
    80004258:	854a                	mv	a0,s2
    8000425a:	00000097          	auipc	ra,0x0
    8000425e:	d70080e7          	jalr	-656(ra) # 80003fca <readi>
    80004262:	47c1                	li	a5,16
    80004264:	fcf518e3          	bne	a0,a5,80004234 <dirlookup+0x3a>
    if(de.inum == 0)
    80004268:	fc045783          	lhu	a5,-64(s0)
    8000426c:	dfe1                	beqz	a5,80004244 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000426e:	fc240593          	addi	a1,s0,-62
    80004272:	854e                	mv	a0,s3
    80004274:	00000097          	auipc	ra,0x0
    80004278:	f6c080e7          	jalr	-148(ra) # 800041e0 <namecmp>
    8000427c:	f561                	bnez	a0,80004244 <dirlookup+0x4a>
      if(poff)
    8000427e:	000a0463          	beqz	s4,80004286 <dirlookup+0x8c>
        *poff = off;
    80004282:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004286:	fc045583          	lhu	a1,-64(s0)
    8000428a:	00092503          	lw	a0,0(s2)
    8000428e:	fffff097          	auipc	ra,0xfffff
    80004292:	750080e7          	jalr	1872(ra) # 800039de <iget>
    80004296:	a011                	j	8000429a <dirlookup+0xa0>
  return 0;
    80004298:	4501                	li	a0,0
}
    8000429a:	70e2                	ld	ra,56(sp)
    8000429c:	7442                	ld	s0,48(sp)
    8000429e:	74a2                	ld	s1,40(sp)
    800042a0:	7902                	ld	s2,32(sp)
    800042a2:	69e2                	ld	s3,24(sp)
    800042a4:	6a42                	ld	s4,16(sp)
    800042a6:	6121                	addi	sp,sp,64
    800042a8:	8082                	ret

00000000800042aa <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800042aa:	711d                	addi	sp,sp,-96
    800042ac:	ec86                	sd	ra,88(sp)
    800042ae:	e8a2                	sd	s0,80(sp)
    800042b0:	e4a6                	sd	s1,72(sp)
    800042b2:	e0ca                	sd	s2,64(sp)
    800042b4:	fc4e                	sd	s3,56(sp)
    800042b6:	f852                	sd	s4,48(sp)
    800042b8:	f456                	sd	s5,40(sp)
    800042ba:	f05a                	sd	s6,32(sp)
    800042bc:	ec5e                	sd	s7,24(sp)
    800042be:	e862                	sd	s8,16(sp)
    800042c0:	e466                	sd	s9,8(sp)
    800042c2:	1080                	addi	s0,sp,96
    800042c4:	84aa                	mv	s1,a0
    800042c6:	8aae                	mv	s5,a1
    800042c8:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800042ca:	00054703          	lbu	a4,0(a0)
    800042ce:	02f00793          	li	a5,47
    800042d2:	02f70363          	beq	a4,a5,800042f8 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800042d6:	ffffd097          	auipc	ra,0xffffd
    800042da:	6de080e7          	jalr	1758(ra) # 800019b4 <myproc>
    800042de:	15053503          	ld	a0,336(a0)
    800042e2:	00000097          	auipc	ra,0x0
    800042e6:	9f6080e7          	jalr	-1546(ra) # 80003cd8 <idup>
    800042ea:	89aa                	mv	s3,a0
  while(*path == '/')
    800042ec:	02f00913          	li	s2,47
  len = path - s;
    800042f0:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800042f2:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800042f4:	4b85                	li	s7,1
    800042f6:	a865                	j	800043ae <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800042f8:	4585                	li	a1,1
    800042fa:	4505                	li	a0,1
    800042fc:	fffff097          	auipc	ra,0xfffff
    80004300:	6e2080e7          	jalr	1762(ra) # 800039de <iget>
    80004304:	89aa                	mv	s3,a0
    80004306:	b7dd                	j	800042ec <namex+0x42>
      iunlockput(ip);
    80004308:	854e                	mv	a0,s3
    8000430a:	00000097          	auipc	ra,0x0
    8000430e:	c6e080e7          	jalr	-914(ra) # 80003f78 <iunlockput>
      return 0;
    80004312:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004314:	854e                	mv	a0,s3
    80004316:	60e6                	ld	ra,88(sp)
    80004318:	6446                	ld	s0,80(sp)
    8000431a:	64a6                	ld	s1,72(sp)
    8000431c:	6906                	ld	s2,64(sp)
    8000431e:	79e2                	ld	s3,56(sp)
    80004320:	7a42                	ld	s4,48(sp)
    80004322:	7aa2                	ld	s5,40(sp)
    80004324:	7b02                	ld	s6,32(sp)
    80004326:	6be2                	ld	s7,24(sp)
    80004328:	6c42                	ld	s8,16(sp)
    8000432a:	6ca2                	ld	s9,8(sp)
    8000432c:	6125                	addi	sp,sp,96
    8000432e:	8082                	ret
      iunlock(ip);
    80004330:	854e                	mv	a0,s3
    80004332:	00000097          	auipc	ra,0x0
    80004336:	aa6080e7          	jalr	-1370(ra) # 80003dd8 <iunlock>
      return ip;
    8000433a:	bfe9                	j	80004314 <namex+0x6a>
      iunlockput(ip);
    8000433c:	854e                	mv	a0,s3
    8000433e:	00000097          	auipc	ra,0x0
    80004342:	c3a080e7          	jalr	-966(ra) # 80003f78 <iunlockput>
      return 0;
    80004346:	89e6                	mv	s3,s9
    80004348:	b7f1                	j	80004314 <namex+0x6a>
  len = path - s;
    8000434a:	40b48633          	sub	a2,s1,a1
    8000434e:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004352:	099c5463          	bge	s8,s9,800043da <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004356:	4639                	li	a2,14
    80004358:	8552                	mv	a0,s4
    8000435a:	ffffd097          	auipc	ra,0xffffd
    8000435e:	9d4080e7          	jalr	-1580(ra) # 80000d2e <memmove>
  while(*path == '/')
    80004362:	0004c783          	lbu	a5,0(s1)
    80004366:	01279763          	bne	a5,s2,80004374 <namex+0xca>
    path++;
    8000436a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000436c:	0004c783          	lbu	a5,0(s1)
    80004370:	ff278de3          	beq	a5,s2,8000436a <namex+0xc0>
    ilock(ip);
    80004374:	854e                	mv	a0,s3
    80004376:	00000097          	auipc	ra,0x0
    8000437a:	9a0080e7          	jalr	-1632(ra) # 80003d16 <ilock>
    if(ip->type != T_DIR){
    8000437e:	04499783          	lh	a5,68(s3)
    80004382:	f97793e3          	bne	a5,s7,80004308 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004386:	000a8563          	beqz	s5,80004390 <namex+0xe6>
    8000438a:	0004c783          	lbu	a5,0(s1)
    8000438e:	d3cd                	beqz	a5,80004330 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004390:	865a                	mv	a2,s6
    80004392:	85d2                	mv	a1,s4
    80004394:	854e                	mv	a0,s3
    80004396:	00000097          	auipc	ra,0x0
    8000439a:	e64080e7          	jalr	-412(ra) # 800041fa <dirlookup>
    8000439e:	8caa                	mv	s9,a0
    800043a0:	dd51                	beqz	a0,8000433c <namex+0x92>
    iunlockput(ip);
    800043a2:	854e                	mv	a0,s3
    800043a4:	00000097          	auipc	ra,0x0
    800043a8:	bd4080e7          	jalr	-1068(ra) # 80003f78 <iunlockput>
    ip = next;
    800043ac:	89e6                	mv	s3,s9
  while(*path == '/')
    800043ae:	0004c783          	lbu	a5,0(s1)
    800043b2:	05279763          	bne	a5,s2,80004400 <namex+0x156>
    path++;
    800043b6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043b8:	0004c783          	lbu	a5,0(s1)
    800043bc:	ff278de3          	beq	a5,s2,800043b6 <namex+0x10c>
  if(*path == 0)
    800043c0:	c79d                	beqz	a5,800043ee <namex+0x144>
    path++;
    800043c2:	85a6                	mv	a1,s1
  len = path - s;
    800043c4:	8cda                	mv	s9,s6
    800043c6:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800043c8:	01278963          	beq	a5,s2,800043da <namex+0x130>
    800043cc:	dfbd                	beqz	a5,8000434a <namex+0xa0>
    path++;
    800043ce:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800043d0:	0004c783          	lbu	a5,0(s1)
    800043d4:	ff279ce3          	bne	a5,s2,800043cc <namex+0x122>
    800043d8:	bf8d                	j	8000434a <namex+0xa0>
    memmove(name, s, len);
    800043da:	2601                	sext.w	a2,a2
    800043dc:	8552                	mv	a0,s4
    800043de:	ffffd097          	auipc	ra,0xffffd
    800043e2:	950080e7          	jalr	-1712(ra) # 80000d2e <memmove>
    name[len] = 0;
    800043e6:	9cd2                	add	s9,s9,s4
    800043e8:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800043ec:	bf9d                	j	80004362 <namex+0xb8>
  if(nameiparent){
    800043ee:	f20a83e3          	beqz	s5,80004314 <namex+0x6a>
    iput(ip);
    800043f2:	854e                	mv	a0,s3
    800043f4:	00000097          	auipc	ra,0x0
    800043f8:	adc080e7          	jalr	-1316(ra) # 80003ed0 <iput>
    return 0;
    800043fc:	4981                	li	s3,0
    800043fe:	bf19                	j	80004314 <namex+0x6a>
  if(*path == 0)
    80004400:	d7fd                	beqz	a5,800043ee <namex+0x144>
  while(*path != '/' && *path != 0)
    80004402:	0004c783          	lbu	a5,0(s1)
    80004406:	85a6                	mv	a1,s1
    80004408:	b7d1                	j	800043cc <namex+0x122>

000000008000440a <dirlink>:
{
    8000440a:	7139                	addi	sp,sp,-64
    8000440c:	fc06                	sd	ra,56(sp)
    8000440e:	f822                	sd	s0,48(sp)
    80004410:	f426                	sd	s1,40(sp)
    80004412:	f04a                	sd	s2,32(sp)
    80004414:	ec4e                	sd	s3,24(sp)
    80004416:	e852                	sd	s4,16(sp)
    80004418:	0080                	addi	s0,sp,64
    8000441a:	892a                	mv	s2,a0
    8000441c:	8a2e                	mv	s4,a1
    8000441e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004420:	4601                	li	a2,0
    80004422:	00000097          	auipc	ra,0x0
    80004426:	dd8080e7          	jalr	-552(ra) # 800041fa <dirlookup>
    8000442a:	e93d                	bnez	a0,800044a0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000442c:	04c92483          	lw	s1,76(s2)
    80004430:	c49d                	beqz	s1,8000445e <dirlink+0x54>
    80004432:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004434:	4741                	li	a4,16
    80004436:	86a6                	mv	a3,s1
    80004438:	fc040613          	addi	a2,s0,-64
    8000443c:	4581                	li	a1,0
    8000443e:	854a                	mv	a0,s2
    80004440:	00000097          	auipc	ra,0x0
    80004444:	b8a080e7          	jalr	-1142(ra) # 80003fca <readi>
    80004448:	47c1                	li	a5,16
    8000444a:	06f51163          	bne	a0,a5,800044ac <dirlink+0xa2>
    if(de.inum == 0)
    8000444e:	fc045783          	lhu	a5,-64(s0)
    80004452:	c791                	beqz	a5,8000445e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004454:	24c1                	addiw	s1,s1,16
    80004456:	04c92783          	lw	a5,76(s2)
    8000445a:	fcf4ede3          	bltu	s1,a5,80004434 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000445e:	4639                	li	a2,14
    80004460:	85d2                	mv	a1,s4
    80004462:	fc240513          	addi	a0,s0,-62
    80004466:	ffffd097          	auipc	ra,0xffffd
    8000446a:	978080e7          	jalr	-1672(ra) # 80000dde <strncpy>
  de.inum = inum;
    8000446e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004472:	4741                	li	a4,16
    80004474:	86a6                	mv	a3,s1
    80004476:	fc040613          	addi	a2,s0,-64
    8000447a:	4581                	li	a1,0
    8000447c:	854a                	mv	a0,s2
    8000447e:	00000097          	auipc	ra,0x0
    80004482:	c44080e7          	jalr	-956(ra) # 800040c2 <writei>
    80004486:	1541                	addi	a0,a0,-16
    80004488:	00a03533          	snez	a0,a0
    8000448c:	40a00533          	neg	a0,a0
}
    80004490:	70e2                	ld	ra,56(sp)
    80004492:	7442                	ld	s0,48(sp)
    80004494:	74a2                	ld	s1,40(sp)
    80004496:	7902                	ld	s2,32(sp)
    80004498:	69e2                	ld	s3,24(sp)
    8000449a:	6a42                	ld	s4,16(sp)
    8000449c:	6121                	addi	sp,sp,64
    8000449e:	8082                	ret
    iput(ip);
    800044a0:	00000097          	auipc	ra,0x0
    800044a4:	a30080e7          	jalr	-1488(ra) # 80003ed0 <iput>
    return -1;
    800044a8:	557d                	li	a0,-1
    800044aa:	b7dd                	j	80004490 <dirlink+0x86>
      panic("dirlink read");
    800044ac:	00004517          	auipc	a0,0x4
    800044b0:	19450513          	addi	a0,a0,404 # 80008640 <syscalls+0x1f0>
    800044b4:	ffffc097          	auipc	ra,0xffffc
    800044b8:	08a080e7          	jalr	138(ra) # 8000053e <panic>

00000000800044bc <namei>:

struct inode*
namei(char *path)
{
    800044bc:	1101                	addi	sp,sp,-32
    800044be:	ec06                	sd	ra,24(sp)
    800044c0:	e822                	sd	s0,16(sp)
    800044c2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800044c4:	fe040613          	addi	a2,s0,-32
    800044c8:	4581                	li	a1,0
    800044ca:	00000097          	auipc	ra,0x0
    800044ce:	de0080e7          	jalr	-544(ra) # 800042aa <namex>
}
    800044d2:	60e2                	ld	ra,24(sp)
    800044d4:	6442                	ld	s0,16(sp)
    800044d6:	6105                	addi	sp,sp,32
    800044d8:	8082                	ret

00000000800044da <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800044da:	1141                	addi	sp,sp,-16
    800044dc:	e406                	sd	ra,8(sp)
    800044de:	e022                	sd	s0,0(sp)
    800044e0:	0800                	addi	s0,sp,16
    800044e2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800044e4:	4585                	li	a1,1
    800044e6:	00000097          	auipc	ra,0x0
    800044ea:	dc4080e7          	jalr	-572(ra) # 800042aa <namex>
}
    800044ee:	60a2                	ld	ra,8(sp)
    800044f0:	6402                	ld	s0,0(sp)
    800044f2:	0141                	addi	sp,sp,16
    800044f4:	8082                	ret

00000000800044f6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800044f6:	1101                	addi	sp,sp,-32
    800044f8:	ec06                	sd	ra,24(sp)
    800044fa:	e822                	sd	s0,16(sp)
    800044fc:	e426                	sd	s1,8(sp)
    800044fe:	e04a                	sd	s2,0(sp)
    80004500:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004502:	0001e917          	auipc	s2,0x1e
    80004506:	84e90913          	addi	s2,s2,-1970 # 80021d50 <log>
    8000450a:	01892583          	lw	a1,24(s2)
    8000450e:	02892503          	lw	a0,40(s2)
    80004512:	fffff097          	auipc	ra,0xfffff
    80004516:	fea080e7          	jalr	-22(ra) # 800034fc <bread>
    8000451a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000451c:	02c92683          	lw	a3,44(s2)
    80004520:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004522:	02d05763          	blez	a3,80004550 <write_head+0x5a>
    80004526:	0001e797          	auipc	a5,0x1e
    8000452a:	85a78793          	addi	a5,a5,-1958 # 80021d80 <log+0x30>
    8000452e:	05c50713          	addi	a4,a0,92
    80004532:	36fd                	addiw	a3,a3,-1
    80004534:	1682                	slli	a3,a3,0x20
    80004536:	9281                	srli	a3,a3,0x20
    80004538:	068a                	slli	a3,a3,0x2
    8000453a:	0001e617          	auipc	a2,0x1e
    8000453e:	84a60613          	addi	a2,a2,-1974 # 80021d84 <log+0x34>
    80004542:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004544:	4390                	lw	a2,0(a5)
    80004546:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004548:	0791                	addi	a5,a5,4
    8000454a:	0711                	addi	a4,a4,4
    8000454c:	fed79ce3          	bne	a5,a3,80004544 <write_head+0x4e>
  }
  bwrite(buf);
    80004550:	8526                	mv	a0,s1
    80004552:	fffff097          	auipc	ra,0xfffff
    80004556:	09c080e7          	jalr	156(ra) # 800035ee <bwrite>
  brelse(buf);
    8000455a:	8526                	mv	a0,s1
    8000455c:	fffff097          	auipc	ra,0xfffff
    80004560:	0d0080e7          	jalr	208(ra) # 8000362c <brelse>
}
    80004564:	60e2                	ld	ra,24(sp)
    80004566:	6442                	ld	s0,16(sp)
    80004568:	64a2                	ld	s1,8(sp)
    8000456a:	6902                	ld	s2,0(sp)
    8000456c:	6105                	addi	sp,sp,32
    8000456e:	8082                	ret

0000000080004570 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004570:	0001e797          	auipc	a5,0x1e
    80004574:	80c7a783          	lw	a5,-2036(a5) # 80021d7c <log+0x2c>
    80004578:	0af05d63          	blez	a5,80004632 <install_trans+0xc2>
{
    8000457c:	7139                	addi	sp,sp,-64
    8000457e:	fc06                	sd	ra,56(sp)
    80004580:	f822                	sd	s0,48(sp)
    80004582:	f426                	sd	s1,40(sp)
    80004584:	f04a                	sd	s2,32(sp)
    80004586:	ec4e                	sd	s3,24(sp)
    80004588:	e852                	sd	s4,16(sp)
    8000458a:	e456                	sd	s5,8(sp)
    8000458c:	e05a                	sd	s6,0(sp)
    8000458e:	0080                	addi	s0,sp,64
    80004590:	8b2a                	mv	s6,a0
    80004592:	0001da97          	auipc	s5,0x1d
    80004596:	7eea8a93          	addi	s5,s5,2030 # 80021d80 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000459a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000459c:	0001d997          	auipc	s3,0x1d
    800045a0:	7b498993          	addi	s3,s3,1972 # 80021d50 <log>
    800045a4:	a00d                	j	800045c6 <install_trans+0x56>
    brelse(lbuf);
    800045a6:	854a                	mv	a0,s2
    800045a8:	fffff097          	auipc	ra,0xfffff
    800045ac:	084080e7          	jalr	132(ra) # 8000362c <brelse>
    brelse(dbuf);
    800045b0:	8526                	mv	a0,s1
    800045b2:	fffff097          	auipc	ra,0xfffff
    800045b6:	07a080e7          	jalr	122(ra) # 8000362c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045ba:	2a05                	addiw	s4,s4,1
    800045bc:	0a91                	addi	s5,s5,4
    800045be:	02c9a783          	lw	a5,44(s3)
    800045c2:	04fa5e63          	bge	s4,a5,8000461e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045c6:	0189a583          	lw	a1,24(s3)
    800045ca:	014585bb          	addw	a1,a1,s4
    800045ce:	2585                	addiw	a1,a1,1
    800045d0:	0289a503          	lw	a0,40(s3)
    800045d4:	fffff097          	auipc	ra,0xfffff
    800045d8:	f28080e7          	jalr	-216(ra) # 800034fc <bread>
    800045dc:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800045de:	000aa583          	lw	a1,0(s5)
    800045e2:	0289a503          	lw	a0,40(s3)
    800045e6:	fffff097          	auipc	ra,0xfffff
    800045ea:	f16080e7          	jalr	-234(ra) # 800034fc <bread>
    800045ee:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800045f0:	40000613          	li	a2,1024
    800045f4:	05890593          	addi	a1,s2,88
    800045f8:	05850513          	addi	a0,a0,88
    800045fc:	ffffc097          	auipc	ra,0xffffc
    80004600:	732080e7          	jalr	1842(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004604:	8526                	mv	a0,s1
    80004606:	fffff097          	auipc	ra,0xfffff
    8000460a:	fe8080e7          	jalr	-24(ra) # 800035ee <bwrite>
    if(recovering == 0)
    8000460e:	f80b1ce3          	bnez	s6,800045a6 <install_trans+0x36>
      bunpin(dbuf);
    80004612:	8526                	mv	a0,s1
    80004614:	fffff097          	auipc	ra,0xfffff
    80004618:	0f2080e7          	jalr	242(ra) # 80003706 <bunpin>
    8000461c:	b769                	j	800045a6 <install_trans+0x36>
}
    8000461e:	70e2                	ld	ra,56(sp)
    80004620:	7442                	ld	s0,48(sp)
    80004622:	74a2                	ld	s1,40(sp)
    80004624:	7902                	ld	s2,32(sp)
    80004626:	69e2                	ld	s3,24(sp)
    80004628:	6a42                	ld	s4,16(sp)
    8000462a:	6aa2                	ld	s5,8(sp)
    8000462c:	6b02                	ld	s6,0(sp)
    8000462e:	6121                	addi	sp,sp,64
    80004630:	8082                	ret
    80004632:	8082                	ret

0000000080004634 <initlog>:
{
    80004634:	7179                	addi	sp,sp,-48
    80004636:	f406                	sd	ra,40(sp)
    80004638:	f022                	sd	s0,32(sp)
    8000463a:	ec26                	sd	s1,24(sp)
    8000463c:	e84a                	sd	s2,16(sp)
    8000463e:	e44e                	sd	s3,8(sp)
    80004640:	1800                	addi	s0,sp,48
    80004642:	892a                	mv	s2,a0
    80004644:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004646:	0001d497          	auipc	s1,0x1d
    8000464a:	70a48493          	addi	s1,s1,1802 # 80021d50 <log>
    8000464e:	00004597          	auipc	a1,0x4
    80004652:	00258593          	addi	a1,a1,2 # 80008650 <syscalls+0x200>
    80004656:	8526                	mv	a0,s1
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	4ee080e7          	jalr	1262(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004660:	0149a583          	lw	a1,20(s3)
    80004664:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004666:	0109a783          	lw	a5,16(s3)
    8000466a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000466c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004670:	854a                	mv	a0,s2
    80004672:	fffff097          	auipc	ra,0xfffff
    80004676:	e8a080e7          	jalr	-374(ra) # 800034fc <bread>
  log.lh.n = lh->n;
    8000467a:	4d34                	lw	a3,88(a0)
    8000467c:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000467e:	02d05563          	blez	a3,800046a8 <initlog+0x74>
    80004682:	05c50793          	addi	a5,a0,92
    80004686:	0001d717          	auipc	a4,0x1d
    8000468a:	6fa70713          	addi	a4,a4,1786 # 80021d80 <log+0x30>
    8000468e:	36fd                	addiw	a3,a3,-1
    80004690:	1682                	slli	a3,a3,0x20
    80004692:	9281                	srli	a3,a3,0x20
    80004694:	068a                	slli	a3,a3,0x2
    80004696:	06050613          	addi	a2,a0,96
    8000469a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000469c:	4390                	lw	a2,0(a5)
    8000469e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800046a0:	0791                	addi	a5,a5,4
    800046a2:	0711                	addi	a4,a4,4
    800046a4:	fed79ce3          	bne	a5,a3,8000469c <initlog+0x68>
  brelse(buf);
    800046a8:	fffff097          	auipc	ra,0xfffff
    800046ac:	f84080e7          	jalr	-124(ra) # 8000362c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800046b0:	4505                	li	a0,1
    800046b2:	00000097          	auipc	ra,0x0
    800046b6:	ebe080e7          	jalr	-322(ra) # 80004570 <install_trans>
  log.lh.n = 0;
    800046ba:	0001d797          	auipc	a5,0x1d
    800046be:	6c07a123          	sw	zero,1730(a5) # 80021d7c <log+0x2c>
  write_head(); // clear the log
    800046c2:	00000097          	auipc	ra,0x0
    800046c6:	e34080e7          	jalr	-460(ra) # 800044f6 <write_head>
}
    800046ca:	70a2                	ld	ra,40(sp)
    800046cc:	7402                	ld	s0,32(sp)
    800046ce:	64e2                	ld	s1,24(sp)
    800046d0:	6942                	ld	s2,16(sp)
    800046d2:	69a2                	ld	s3,8(sp)
    800046d4:	6145                	addi	sp,sp,48
    800046d6:	8082                	ret

00000000800046d8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800046d8:	1101                	addi	sp,sp,-32
    800046da:	ec06                	sd	ra,24(sp)
    800046dc:	e822                	sd	s0,16(sp)
    800046de:	e426                	sd	s1,8(sp)
    800046e0:	e04a                	sd	s2,0(sp)
    800046e2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800046e4:	0001d517          	auipc	a0,0x1d
    800046e8:	66c50513          	addi	a0,a0,1644 # 80021d50 <log>
    800046ec:	ffffc097          	auipc	ra,0xffffc
    800046f0:	4ea080e7          	jalr	1258(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800046f4:	0001d497          	auipc	s1,0x1d
    800046f8:	65c48493          	addi	s1,s1,1628 # 80021d50 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046fc:	4979                	li	s2,30
    800046fe:	a039                	j	8000470c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004700:	85a6                	mv	a1,s1
    80004702:	8526                	mv	a0,s1
    80004704:	ffffe097          	auipc	ra,0xffffe
    80004708:	960080e7          	jalr	-1696(ra) # 80002064 <sleep>
    if(log.committing){
    8000470c:	50dc                	lw	a5,36(s1)
    8000470e:	fbed                	bnez	a5,80004700 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004710:	509c                	lw	a5,32(s1)
    80004712:	0017871b          	addiw	a4,a5,1
    80004716:	0007069b          	sext.w	a3,a4
    8000471a:	0027179b          	slliw	a5,a4,0x2
    8000471e:	9fb9                	addw	a5,a5,a4
    80004720:	0017979b          	slliw	a5,a5,0x1
    80004724:	54d8                	lw	a4,44(s1)
    80004726:	9fb9                	addw	a5,a5,a4
    80004728:	00f95963          	bge	s2,a5,8000473a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000472c:	85a6                	mv	a1,s1
    8000472e:	8526                	mv	a0,s1
    80004730:	ffffe097          	auipc	ra,0xffffe
    80004734:	934080e7          	jalr	-1740(ra) # 80002064 <sleep>
    80004738:	bfd1                	j	8000470c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000473a:	0001d517          	auipc	a0,0x1d
    8000473e:	61650513          	addi	a0,a0,1558 # 80021d50 <log>
    80004742:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004744:	ffffc097          	auipc	ra,0xffffc
    80004748:	546080e7          	jalr	1350(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000474c:	60e2                	ld	ra,24(sp)
    8000474e:	6442                	ld	s0,16(sp)
    80004750:	64a2                	ld	s1,8(sp)
    80004752:	6902                	ld	s2,0(sp)
    80004754:	6105                	addi	sp,sp,32
    80004756:	8082                	ret

0000000080004758 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004758:	7139                	addi	sp,sp,-64
    8000475a:	fc06                	sd	ra,56(sp)
    8000475c:	f822                	sd	s0,48(sp)
    8000475e:	f426                	sd	s1,40(sp)
    80004760:	f04a                	sd	s2,32(sp)
    80004762:	ec4e                	sd	s3,24(sp)
    80004764:	e852                	sd	s4,16(sp)
    80004766:	e456                	sd	s5,8(sp)
    80004768:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000476a:	0001d497          	auipc	s1,0x1d
    8000476e:	5e648493          	addi	s1,s1,1510 # 80021d50 <log>
    80004772:	8526                	mv	a0,s1
    80004774:	ffffc097          	auipc	ra,0xffffc
    80004778:	462080e7          	jalr	1122(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000477c:	509c                	lw	a5,32(s1)
    8000477e:	37fd                	addiw	a5,a5,-1
    80004780:	0007891b          	sext.w	s2,a5
    80004784:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004786:	50dc                	lw	a5,36(s1)
    80004788:	e7b9                	bnez	a5,800047d6 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000478a:	04091e63          	bnez	s2,800047e6 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000478e:	0001d497          	auipc	s1,0x1d
    80004792:	5c248493          	addi	s1,s1,1474 # 80021d50 <log>
    80004796:	4785                	li	a5,1
    80004798:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000479a:	8526                	mv	a0,s1
    8000479c:	ffffc097          	auipc	ra,0xffffc
    800047a0:	4ee080e7          	jalr	1262(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800047a4:	54dc                	lw	a5,44(s1)
    800047a6:	06f04763          	bgtz	a5,80004814 <end_op+0xbc>
    acquire(&log.lock);
    800047aa:	0001d497          	auipc	s1,0x1d
    800047ae:	5a648493          	addi	s1,s1,1446 # 80021d50 <log>
    800047b2:	8526                	mv	a0,s1
    800047b4:	ffffc097          	auipc	ra,0xffffc
    800047b8:	422080e7          	jalr	1058(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800047bc:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800047c0:	8526                	mv	a0,s1
    800047c2:	ffffe097          	auipc	ra,0xffffe
    800047c6:	906080e7          	jalr	-1786(ra) # 800020c8 <wakeup>
    release(&log.lock);
    800047ca:	8526                	mv	a0,s1
    800047cc:	ffffc097          	auipc	ra,0xffffc
    800047d0:	4be080e7          	jalr	1214(ra) # 80000c8a <release>
}
    800047d4:	a03d                	j	80004802 <end_op+0xaa>
    panic("log.committing");
    800047d6:	00004517          	auipc	a0,0x4
    800047da:	e8250513          	addi	a0,a0,-382 # 80008658 <syscalls+0x208>
    800047de:	ffffc097          	auipc	ra,0xffffc
    800047e2:	d60080e7          	jalr	-672(ra) # 8000053e <panic>
    wakeup(&log);
    800047e6:	0001d497          	auipc	s1,0x1d
    800047ea:	56a48493          	addi	s1,s1,1386 # 80021d50 <log>
    800047ee:	8526                	mv	a0,s1
    800047f0:	ffffe097          	auipc	ra,0xffffe
    800047f4:	8d8080e7          	jalr	-1832(ra) # 800020c8 <wakeup>
  release(&log.lock);
    800047f8:	8526                	mv	a0,s1
    800047fa:	ffffc097          	auipc	ra,0xffffc
    800047fe:	490080e7          	jalr	1168(ra) # 80000c8a <release>
}
    80004802:	70e2                	ld	ra,56(sp)
    80004804:	7442                	ld	s0,48(sp)
    80004806:	74a2                	ld	s1,40(sp)
    80004808:	7902                	ld	s2,32(sp)
    8000480a:	69e2                	ld	s3,24(sp)
    8000480c:	6a42                	ld	s4,16(sp)
    8000480e:	6aa2                	ld	s5,8(sp)
    80004810:	6121                	addi	sp,sp,64
    80004812:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004814:	0001da97          	auipc	s5,0x1d
    80004818:	56ca8a93          	addi	s5,s5,1388 # 80021d80 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000481c:	0001da17          	auipc	s4,0x1d
    80004820:	534a0a13          	addi	s4,s4,1332 # 80021d50 <log>
    80004824:	018a2583          	lw	a1,24(s4)
    80004828:	012585bb          	addw	a1,a1,s2
    8000482c:	2585                	addiw	a1,a1,1
    8000482e:	028a2503          	lw	a0,40(s4)
    80004832:	fffff097          	auipc	ra,0xfffff
    80004836:	cca080e7          	jalr	-822(ra) # 800034fc <bread>
    8000483a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000483c:	000aa583          	lw	a1,0(s5)
    80004840:	028a2503          	lw	a0,40(s4)
    80004844:	fffff097          	auipc	ra,0xfffff
    80004848:	cb8080e7          	jalr	-840(ra) # 800034fc <bread>
    8000484c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000484e:	40000613          	li	a2,1024
    80004852:	05850593          	addi	a1,a0,88
    80004856:	05848513          	addi	a0,s1,88
    8000485a:	ffffc097          	auipc	ra,0xffffc
    8000485e:	4d4080e7          	jalr	1236(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004862:	8526                	mv	a0,s1
    80004864:	fffff097          	auipc	ra,0xfffff
    80004868:	d8a080e7          	jalr	-630(ra) # 800035ee <bwrite>
    brelse(from);
    8000486c:	854e                	mv	a0,s3
    8000486e:	fffff097          	auipc	ra,0xfffff
    80004872:	dbe080e7          	jalr	-578(ra) # 8000362c <brelse>
    brelse(to);
    80004876:	8526                	mv	a0,s1
    80004878:	fffff097          	auipc	ra,0xfffff
    8000487c:	db4080e7          	jalr	-588(ra) # 8000362c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004880:	2905                	addiw	s2,s2,1
    80004882:	0a91                	addi	s5,s5,4
    80004884:	02ca2783          	lw	a5,44(s4)
    80004888:	f8f94ee3          	blt	s2,a5,80004824 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000488c:	00000097          	auipc	ra,0x0
    80004890:	c6a080e7          	jalr	-918(ra) # 800044f6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004894:	4501                	li	a0,0
    80004896:	00000097          	auipc	ra,0x0
    8000489a:	cda080e7          	jalr	-806(ra) # 80004570 <install_trans>
    log.lh.n = 0;
    8000489e:	0001d797          	auipc	a5,0x1d
    800048a2:	4c07af23          	sw	zero,1246(a5) # 80021d7c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800048a6:	00000097          	auipc	ra,0x0
    800048aa:	c50080e7          	jalr	-944(ra) # 800044f6 <write_head>
    800048ae:	bdf5                	j	800047aa <end_op+0x52>

00000000800048b0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048b0:	1101                	addi	sp,sp,-32
    800048b2:	ec06                	sd	ra,24(sp)
    800048b4:	e822                	sd	s0,16(sp)
    800048b6:	e426                	sd	s1,8(sp)
    800048b8:	e04a                	sd	s2,0(sp)
    800048ba:	1000                	addi	s0,sp,32
    800048bc:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800048be:	0001d917          	auipc	s2,0x1d
    800048c2:	49290913          	addi	s2,s2,1170 # 80021d50 <log>
    800048c6:	854a                	mv	a0,s2
    800048c8:	ffffc097          	auipc	ra,0xffffc
    800048cc:	30e080e7          	jalr	782(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800048d0:	02c92603          	lw	a2,44(s2)
    800048d4:	47f5                	li	a5,29
    800048d6:	06c7c563          	blt	a5,a2,80004940 <log_write+0x90>
    800048da:	0001d797          	auipc	a5,0x1d
    800048de:	4927a783          	lw	a5,1170(a5) # 80021d6c <log+0x1c>
    800048e2:	37fd                	addiw	a5,a5,-1
    800048e4:	04f65e63          	bge	a2,a5,80004940 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800048e8:	0001d797          	auipc	a5,0x1d
    800048ec:	4887a783          	lw	a5,1160(a5) # 80021d70 <log+0x20>
    800048f0:	06f05063          	blez	a5,80004950 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800048f4:	4781                	li	a5,0
    800048f6:	06c05563          	blez	a2,80004960 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800048fa:	44cc                	lw	a1,12(s1)
    800048fc:	0001d717          	auipc	a4,0x1d
    80004900:	48470713          	addi	a4,a4,1156 # 80021d80 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004904:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004906:	4314                	lw	a3,0(a4)
    80004908:	04b68c63          	beq	a3,a1,80004960 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000490c:	2785                	addiw	a5,a5,1
    8000490e:	0711                	addi	a4,a4,4
    80004910:	fef61be3          	bne	a2,a5,80004906 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004914:	0621                	addi	a2,a2,8
    80004916:	060a                	slli	a2,a2,0x2
    80004918:	0001d797          	auipc	a5,0x1d
    8000491c:	43878793          	addi	a5,a5,1080 # 80021d50 <log>
    80004920:	963e                	add	a2,a2,a5
    80004922:	44dc                	lw	a5,12(s1)
    80004924:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004926:	8526                	mv	a0,s1
    80004928:	fffff097          	auipc	ra,0xfffff
    8000492c:	da2080e7          	jalr	-606(ra) # 800036ca <bpin>
    log.lh.n++;
    80004930:	0001d717          	auipc	a4,0x1d
    80004934:	42070713          	addi	a4,a4,1056 # 80021d50 <log>
    80004938:	575c                	lw	a5,44(a4)
    8000493a:	2785                	addiw	a5,a5,1
    8000493c:	d75c                	sw	a5,44(a4)
    8000493e:	a835                	j	8000497a <log_write+0xca>
    panic("too big a transaction");
    80004940:	00004517          	auipc	a0,0x4
    80004944:	d2850513          	addi	a0,a0,-728 # 80008668 <syscalls+0x218>
    80004948:	ffffc097          	auipc	ra,0xffffc
    8000494c:	bf6080e7          	jalr	-1034(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004950:	00004517          	auipc	a0,0x4
    80004954:	d3050513          	addi	a0,a0,-720 # 80008680 <syscalls+0x230>
    80004958:	ffffc097          	auipc	ra,0xffffc
    8000495c:	be6080e7          	jalr	-1050(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004960:	00878713          	addi	a4,a5,8
    80004964:	00271693          	slli	a3,a4,0x2
    80004968:	0001d717          	auipc	a4,0x1d
    8000496c:	3e870713          	addi	a4,a4,1000 # 80021d50 <log>
    80004970:	9736                	add	a4,a4,a3
    80004972:	44d4                	lw	a3,12(s1)
    80004974:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004976:	faf608e3          	beq	a2,a5,80004926 <log_write+0x76>
  }
  release(&log.lock);
    8000497a:	0001d517          	auipc	a0,0x1d
    8000497e:	3d650513          	addi	a0,a0,982 # 80021d50 <log>
    80004982:	ffffc097          	auipc	ra,0xffffc
    80004986:	308080e7          	jalr	776(ra) # 80000c8a <release>
}
    8000498a:	60e2                	ld	ra,24(sp)
    8000498c:	6442                	ld	s0,16(sp)
    8000498e:	64a2                	ld	s1,8(sp)
    80004990:	6902                	ld	s2,0(sp)
    80004992:	6105                	addi	sp,sp,32
    80004994:	8082                	ret

0000000080004996 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004996:	1101                	addi	sp,sp,-32
    80004998:	ec06                	sd	ra,24(sp)
    8000499a:	e822                	sd	s0,16(sp)
    8000499c:	e426                	sd	s1,8(sp)
    8000499e:	e04a                	sd	s2,0(sp)
    800049a0:	1000                	addi	s0,sp,32
    800049a2:	84aa                	mv	s1,a0
    800049a4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800049a6:	00004597          	auipc	a1,0x4
    800049aa:	cfa58593          	addi	a1,a1,-774 # 800086a0 <syscalls+0x250>
    800049ae:	0521                	addi	a0,a0,8
    800049b0:	ffffc097          	auipc	ra,0xffffc
    800049b4:	196080e7          	jalr	406(ra) # 80000b46 <initlock>
  lk->name = name;
    800049b8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800049bc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049c0:	0204a423          	sw	zero,40(s1)
}
    800049c4:	60e2                	ld	ra,24(sp)
    800049c6:	6442                	ld	s0,16(sp)
    800049c8:	64a2                	ld	s1,8(sp)
    800049ca:	6902                	ld	s2,0(sp)
    800049cc:	6105                	addi	sp,sp,32
    800049ce:	8082                	ret

00000000800049d0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800049d0:	1101                	addi	sp,sp,-32
    800049d2:	ec06                	sd	ra,24(sp)
    800049d4:	e822                	sd	s0,16(sp)
    800049d6:	e426                	sd	s1,8(sp)
    800049d8:	e04a                	sd	s2,0(sp)
    800049da:	1000                	addi	s0,sp,32
    800049dc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049de:	00850913          	addi	s2,a0,8
    800049e2:	854a                	mv	a0,s2
    800049e4:	ffffc097          	auipc	ra,0xffffc
    800049e8:	1f2080e7          	jalr	498(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800049ec:	409c                	lw	a5,0(s1)
    800049ee:	cb89                	beqz	a5,80004a00 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800049f0:	85ca                	mv	a1,s2
    800049f2:	8526                	mv	a0,s1
    800049f4:	ffffd097          	auipc	ra,0xffffd
    800049f8:	670080e7          	jalr	1648(ra) # 80002064 <sleep>
  while (lk->locked) {
    800049fc:	409c                	lw	a5,0(s1)
    800049fe:	fbed                	bnez	a5,800049f0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a00:	4785                	li	a5,1
    80004a02:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a04:	ffffd097          	auipc	ra,0xffffd
    80004a08:	fb0080e7          	jalr	-80(ra) # 800019b4 <myproc>
    80004a0c:	591c                	lw	a5,48(a0)
    80004a0e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a10:	854a                	mv	a0,s2
    80004a12:	ffffc097          	auipc	ra,0xffffc
    80004a16:	278080e7          	jalr	632(ra) # 80000c8a <release>
}
    80004a1a:	60e2                	ld	ra,24(sp)
    80004a1c:	6442                	ld	s0,16(sp)
    80004a1e:	64a2                	ld	s1,8(sp)
    80004a20:	6902                	ld	s2,0(sp)
    80004a22:	6105                	addi	sp,sp,32
    80004a24:	8082                	ret

0000000080004a26 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a26:	1101                	addi	sp,sp,-32
    80004a28:	ec06                	sd	ra,24(sp)
    80004a2a:	e822                	sd	s0,16(sp)
    80004a2c:	e426                	sd	s1,8(sp)
    80004a2e:	e04a                	sd	s2,0(sp)
    80004a30:	1000                	addi	s0,sp,32
    80004a32:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a34:	00850913          	addi	s2,a0,8
    80004a38:	854a                	mv	a0,s2
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	19c080e7          	jalr	412(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004a42:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a46:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a4a:	8526                	mv	a0,s1
    80004a4c:	ffffd097          	auipc	ra,0xffffd
    80004a50:	67c080e7          	jalr	1660(ra) # 800020c8 <wakeup>
  release(&lk->lk);
    80004a54:	854a                	mv	a0,s2
    80004a56:	ffffc097          	auipc	ra,0xffffc
    80004a5a:	234080e7          	jalr	564(ra) # 80000c8a <release>
}
    80004a5e:	60e2                	ld	ra,24(sp)
    80004a60:	6442                	ld	s0,16(sp)
    80004a62:	64a2                	ld	s1,8(sp)
    80004a64:	6902                	ld	s2,0(sp)
    80004a66:	6105                	addi	sp,sp,32
    80004a68:	8082                	ret

0000000080004a6a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a6a:	7179                	addi	sp,sp,-48
    80004a6c:	f406                	sd	ra,40(sp)
    80004a6e:	f022                	sd	s0,32(sp)
    80004a70:	ec26                	sd	s1,24(sp)
    80004a72:	e84a                	sd	s2,16(sp)
    80004a74:	e44e                	sd	s3,8(sp)
    80004a76:	1800                	addi	s0,sp,48
    80004a78:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a7a:	00850913          	addi	s2,a0,8
    80004a7e:	854a                	mv	a0,s2
    80004a80:	ffffc097          	auipc	ra,0xffffc
    80004a84:	156080e7          	jalr	342(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a88:	409c                	lw	a5,0(s1)
    80004a8a:	ef99                	bnez	a5,80004aa8 <holdingsleep+0x3e>
    80004a8c:	4481                	li	s1,0
  release(&lk->lk);
    80004a8e:	854a                	mv	a0,s2
    80004a90:	ffffc097          	auipc	ra,0xffffc
    80004a94:	1fa080e7          	jalr	506(ra) # 80000c8a <release>
  return r;
}
    80004a98:	8526                	mv	a0,s1
    80004a9a:	70a2                	ld	ra,40(sp)
    80004a9c:	7402                	ld	s0,32(sp)
    80004a9e:	64e2                	ld	s1,24(sp)
    80004aa0:	6942                	ld	s2,16(sp)
    80004aa2:	69a2                	ld	s3,8(sp)
    80004aa4:	6145                	addi	sp,sp,48
    80004aa6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004aa8:	0284a983          	lw	s3,40(s1)
    80004aac:	ffffd097          	auipc	ra,0xffffd
    80004ab0:	f08080e7          	jalr	-248(ra) # 800019b4 <myproc>
    80004ab4:	5904                	lw	s1,48(a0)
    80004ab6:	413484b3          	sub	s1,s1,s3
    80004aba:	0014b493          	seqz	s1,s1
    80004abe:	bfc1                	j	80004a8e <holdingsleep+0x24>

0000000080004ac0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ac0:	1141                	addi	sp,sp,-16
    80004ac2:	e406                	sd	ra,8(sp)
    80004ac4:	e022                	sd	s0,0(sp)
    80004ac6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004ac8:	00004597          	auipc	a1,0x4
    80004acc:	be858593          	addi	a1,a1,-1048 # 800086b0 <syscalls+0x260>
    80004ad0:	0001d517          	auipc	a0,0x1d
    80004ad4:	3c850513          	addi	a0,a0,968 # 80021e98 <ftable>
    80004ad8:	ffffc097          	auipc	ra,0xffffc
    80004adc:	06e080e7          	jalr	110(ra) # 80000b46 <initlock>
}
    80004ae0:	60a2                	ld	ra,8(sp)
    80004ae2:	6402                	ld	s0,0(sp)
    80004ae4:	0141                	addi	sp,sp,16
    80004ae6:	8082                	ret

0000000080004ae8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004ae8:	1101                	addi	sp,sp,-32
    80004aea:	ec06                	sd	ra,24(sp)
    80004aec:	e822                	sd	s0,16(sp)
    80004aee:	e426                	sd	s1,8(sp)
    80004af0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004af2:	0001d517          	auipc	a0,0x1d
    80004af6:	3a650513          	addi	a0,a0,934 # 80021e98 <ftable>
    80004afa:	ffffc097          	auipc	ra,0xffffc
    80004afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b02:	0001d497          	auipc	s1,0x1d
    80004b06:	3ae48493          	addi	s1,s1,942 # 80021eb0 <ftable+0x18>
    80004b0a:	0001e717          	auipc	a4,0x1e
    80004b0e:	34670713          	addi	a4,a4,838 # 80022e50 <disk>
    if(f->ref == 0){
    80004b12:	40dc                	lw	a5,4(s1)
    80004b14:	cf99                	beqz	a5,80004b32 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b16:	02848493          	addi	s1,s1,40
    80004b1a:	fee49ce3          	bne	s1,a4,80004b12 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b1e:	0001d517          	auipc	a0,0x1d
    80004b22:	37a50513          	addi	a0,a0,890 # 80021e98 <ftable>
    80004b26:	ffffc097          	auipc	ra,0xffffc
    80004b2a:	164080e7          	jalr	356(ra) # 80000c8a <release>
  return 0;
    80004b2e:	4481                	li	s1,0
    80004b30:	a819                	j	80004b46 <filealloc+0x5e>
      f->ref = 1;
    80004b32:	4785                	li	a5,1
    80004b34:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b36:	0001d517          	auipc	a0,0x1d
    80004b3a:	36250513          	addi	a0,a0,866 # 80021e98 <ftable>
    80004b3e:	ffffc097          	auipc	ra,0xffffc
    80004b42:	14c080e7          	jalr	332(ra) # 80000c8a <release>
}
    80004b46:	8526                	mv	a0,s1
    80004b48:	60e2                	ld	ra,24(sp)
    80004b4a:	6442                	ld	s0,16(sp)
    80004b4c:	64a2                	ld	s1,8(sp)
    80004b4e:	6105                	addi	sp,sp,32
    80004b50:	8082                	ret

0000000080004b52 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b52:	1101                	addi	sp,sp,-32
    80004b54:	ec06                	sd	ra,24(sp)
    80004b56:	e822                	sd	s0,16(sp)
    80004b58:	e426                	sd	s1,8(sp)
    80004b5a:	1000                	addi	s0,sp,32
    80004b5c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b5e:	0001d517          	auipc	a0,0x1d
    80004b62:	33a50513          	addi	a0,a0,826 # 80021e98 <ftable>
    80004b66:	ffffc097          	auipc	ra,0xffffc
    80004b6a:	070080e7          	jalr	112(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004b6e:	40dc                	lw	a5,4(s1)
    80004b70:	02f05263          	blez	a5,80004b94 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b74:	2785                	addiw	a5,a5,1
    80004b76:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b78:	0001d517          	auipc	a0,0x1d
    80004b7c:	32050513          	addi	a0,a0,800 # 80021e98 <ftable>
    80004b80:	ffffc097          	auipc	ra,0xffffc
    80004b84:	10a080e7          	jalr	266(ra) # 80000c8a <release>
  return f;
}
    80004b88:	8526                	mv	a0,s1
    80004b8a:	60e2                	ld	ra,24(sp)
    80004b8c:	6442                	ld	s0,16(sp)
    80004b8e:	64a2                	ld	s1,8(sp)
    80004b90:	6105                	addi	sp,sp,32
    80004b92:	8082                	ret
    panic("filedup");
    80004b94:	00004517          	auipc	a0,0x4
    80004b98:	b2450513          	addi	a0,a0,-1244 # 800086b8 <syscalls+0x268>
    80004b9c:	ffffc097          	auipc	ra,0xffffc
    80004ba0:	9a2080e7          	jalr	-1630(ra) # 8000053e <panic>

0000000080004ba4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004ba4:	7139                	addi	sp,sp,-64
    80004ba6:	fc06                	sd	ra,56(sp)
    80004ba8:	f822                	sd	s0,48(sp)
    80004baa:	f426                	sd	s1,40(sp)
    80004bac:	f04a                	sd	s2,32(sp)
    80004bae:	ec4e                	sd	s3,24(sp)
    80004bb0:	e852                	sd	s4,16(sp)
    80004bb2:	e456                	sd	s5,8(sp)
    80004bb4:	0080                	addi	s0,sp,64
    80004bb6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004bb8:	0001d517          	auipc	a0,0x1d
    80004bbc:	2e050513          	addi	a0,a0,736 # 80021e98 <ftable>
    80004bc0:	ffffc097          	auipc	ra,0xffffc
    80004bc4:	016080e7          	jalr	22(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004bc8:	40dc                	lw	a5,4(s1)
    80004bca:	06f05163          	blez	a5,80004c2c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004bce:	37fd                	addiw	a5,a5,-1
    80004bd0:	0007871b          	sext.w	a4,a5
    80004bd4:	c0dc                	sw	a5,4(s1)
    80004bd6:	06e04363          	bgtz	a4,80004c3c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004bda:	0004a903          	lw	s2,0(s1)
    80004bde:	0094ca83          	lbu	s5,9(s1)
    80004be2:	0104ba03          	ld	s4,16(s1)
    80004be6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004bea:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004bee:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004bf2:	0001d517          	auipc	a0,0x1d
    80004bf6:	2a650513          	addi	a0,a0,678 # 80021e98 <ftable>
    80004bfa:	ffffc097          	auipc	ra,0xffffc
    80004bfe:	090080e7          	jalr	144(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004c02:	4785                	li	a5,1
    80004c04:	04f90d63          	beq	s2,a5,80004c5e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c08:	3979                	addiw	s2,s2,-2
    80004c0a:	4785                	li	a5,1
    80004c0c:	0527e063          	bltu	a5,s2,80004c4c <fileclose+0xa8>
    begin_op();
    80004c10:	00000097          	auipc	ra,0x0
    80004c14:	ac8080e7          	jalr	-1336(ra) # 800046d8 <begin_op>
    iput(ff.ip);
    80004c18:	854e                	mv	a0,s3
    80004c1a:	fffff097          	auipc	ra,0xfffff
    80004c1e:	2b6080e7          	jalr	694(ra) # 80003ed0 <iput>
    end_op();
    80004c22:	00000097          	auipc	ra,0x0
    80004c26:	b36080e7          	jalr	-1226(ra) # 80004758 <end_op>
    80004c2a:	a00d                	j	80004c4c <fileclose+0xa8>
    panic("fileclose");
    80004c2c:	00004517          	auipc	a0,0x4
    80004c30:	a9450513          	addi	a0,a0,-1388 # 800086c0 <syscalls+0x270>
    80004c34:	ffffc097          	auipc	ra,0xffffc
    80004c38:	90a080e7          	jalr	-1782(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004c3c:	0001d517          	auipc	a0,0x1d
    80004c40:	25c50513          	addi	a0,a0,604 # 80021e98 <ftable>
    80004c44:	ffffc097          	auipc	ra,0xffffc
    80004c48:	046080e7          	jalr	70(ra) # 80000c8a <release>
  }
}
    80004c4c:	70e2                	ld	ra,56(sp)
    80004c4e:	7442                	ld	s0,48(sp)
    80004c50:	74a2                	ld	s1,40(sp)
    80004c52:	7902                	ld	s2,32(sp)
    80004c54:	69e2                	ld	s3,24(sp)
    80004c56:	6a42                	ld	s4,16(sp)
    80004c58:	6aa2                	ld	s5,8(sp)
    80004c5a:	6121                	addi	sp,sp,64
    80004c5c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c5e:	85d6                	mv	a1,s5
    80004c60:	8552                	mv	a0,s4
    80004c62:	00000097          	auipc	ra,0x0
    80004c66:	34c080e7          	jalr	844(ra) # 80004fae <pipeclose>
    80004c6a:	b7cd                	j	80004c4c <fileclose+0xa8>

0000000080004c6c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c6c:	715d                	addi	sp,sp,-80
    80004c6e:	e486                	sd	ra,72(sp)
    80004c70:	e0a2                	sd	s0,64(sp)
    80004c72:	fc26                	sd	s1,56(sp)
    80004c74:	f84a                	sd	s2,48(sp)
    80004c76:	f44e                	sd	s3,40(sp)
    80004c78:	0880                	addi	s0,sp,80
    80004c7a:	84aa                	mv	s1,a0
    80004c7c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c7e:	ffffd097          	auipc	ra,0xffffd
    80004c82:	d36080e7          	jalr	-714(ra) # 800019b4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c86:	409c                	lw	a5,0(s1)
    80004c88:	37f9                	addiw	a5,a5,-2
    80004c8a:	4705                	li	a4,1
    80004c8c:	04f76763          	bltu	a4,a5,80004cda <filestat+0x6e>
    80004c90:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c92:	6c88                	ld	a0,24(s1)
    80004c94:	fffff097          	auipc	ra,0xfffff
    80004c98:	082080e7          	jalr	130(ra) # 80003d16 <ilock>
    stati(f->ip, &st);
    80004c9c:	fb840593          	addi	a1,s0,-72
    80004ca0:	6c88                	ld	a0,24(s1)
    80004ca2:	fffff097          	auipc	ra,0xfffff
    80004ca6:	2fe080e7          	jalr	766(ra) # 80003fa0 <stati>
    iunlock(f->ip);
    80004caa:	6c88                	ld	a0,24(s1)
    80004cac:	fffff097          	auipc	ra,0xfffff
    80004cb0:	12c080e7          	jalr	300(ra) # 80003dd8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004cb4:	46e1                	li	a3,24
    80004cb6:	fb840613          	addi	a2,s0,-72
    80004cba:	85ce                	mv	a1,s3
    80004cbc:	05093503          	ld	a0,80(s2)
    80004cc0:	ffffd097          	auipc	ra,0xffffd
    80004cc4:	9b0080e7          	jalr	-1616(ra) # 80001670 <copyout>
    80004cc8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ccc:	60a6                	ld	ra,72(sp)
    80004cce:	6406                	ld	s0,64(sp)
    80004cd0:	74e2                	ld	s1,56(sp)
    80004cd2:	7942                	ld	s2,48(sp)
    80004cd4:	79a2                	ld	s3,40(sp)
    80004cd6:	6161                	addi	sp,sp,80
    80004cd8:	8082                	ret
  return -1;
    80004cda:	557d                	li	a0,-1
    80004cdc:	bfc5                	j	80004ccc <filestat+0x60>

0000000080004cde <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004cde:	7179                	addi	sp,sp,-48
    80004ce0:	f406                	sd	ra,40(sp)
    80004ce2:	f022                	sd	s0,32(sp)
    80004ce4:	ec26                	sd	s1,24(sp)
    80004ce6:	e84a                	sd	s2,16(sp)
    80004ce8:	e44e                	sd	s3,8(sp)
    80004cea:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004cec:	00854783          	lbu	a5,8(a0)
    80004cf0:	c3d5                	beqz	a5,80004d94 <fileread+0xb6>
    80004cf2:	84aa                	mv	s1,a0
    80004cf4:	89ae                	mv	s3,a1
    80004cf6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cf8:	411c                	lw	a5,0(a0)
    80004cfa:	4705                	li	a4,1
    80004cfc:	04e78963          	beq	a5,a4,80004d4e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d00:	470d                	li	a4,3
    80004d02:	04e78d63          	beq	a5,a4,80004d5c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d06:	4709                	li	a4,2
    80004d08:	06e79e63          	bne	a5,a4,80004d84 <fileread+0xa6>
    ilock(f->ip);
    80004d0c:	6d08                	ld	a0,24(a0)
    80004d0e:	fffff097          	auipc	ra,0xfffff
    80004d12:	008080e7          	jalr	8(ra) # 80003d16 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d16:	874a                	mv	a4,s2
    80004d18:	5094                	lw	a3,32(s1)
    80004d1a:	864e                	mv	a2,s3
    80004d1c:	4585                	li	a1,1
    80004d1e:	6c88                	ld	a0,24(s1)
    80004d20:	fffff097          	auipc	ra,0xfffff
    80004d24:	2aa080e7          	jalr	682(ra) # 80003fca <readi>
    80004d28:	892a                	mv	s2,a0
    80004d2a:	00a05563          	blez	a0,80004d34 <fileread+0x56>
      f->off += r;
    80004d2e:	509c                	lw	a5,32(s1)
    80004d30:	9fa9                	addw	a5,a5,a0
    80004d32:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d34:	6c88                	ld	a0,24(s1)
    80004d36:	fffff097          	auipc	ra,0xfffff
    80004d3a:	0a2080e7          	jalr	162(ra) # 80003dd8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d3e:	854a                	mv	a0,s2
    80004d40:	70a2                	ld	ra,40(sp)
    80004d42:	7402                	ld	s0,32(sp)
    80004d44:	64e2                	ld	s1,24(sp)
    80004d46:	6942                	ld	s2,16(sp)
    80004d48:	69a2                	ld	s3,8(sp)
    80004d4a:	6145                	addi	sp,sp,48
    80004d4c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d4e:	6908                	ld	a0,16(a0)
    80004d50:	00000097          	auipc	ra,0x0
    80004d54:	3c6080e7          	jalr	966(ra) # 80005116 <piperead>
    80004d58:	892a                	mv	s2,a0
    80004d5a:	b7d5                	j	80004d3e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d5c:	02451783          	lh	a5,36(a0)
    80004d60:	03079693          	slli	a3,a5,0x30
    80004d64:	92c1                	srli	a3,a3,0x30
    80004d66:	4725                	li	a4,9
    80004d68:	02d76863          	bltu	a4,a3,80004d98 <fileread+0xba>
    80004d6c:	0792                	slli	a5,a5,0x4
    80004d6e:	0001d717          	auipc	a4,0x1d
    80004d72:	08a70713          	addi	a4,a4,138 # 80021df8 <devsw>
    80004d76:	97ba                	add	a5,a5,a4
    80004d78:	639c                	ld	a5,0(a5)
    80004d7a:	c38d                	beqz	a5,80004d9c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d7c:	4505                	li	a0,1
    80004d7e:	9782                	jalr	a5
    80004d80:	892a                	mv	s2,a0
    80004d82:	bf75                	j	80004d3e <fileread+0x60>
    panic("fileread");
    80004d84:	00004517          	auipc	a0,0x4
    80004d88:	94c50513          	addi	a0,a0,-1716 # 800086d0 <syscalls+0x280>
    80004d8c:	ffffb097          	auipc	ra,0xffffb
    80004d90:	7b2080e7          	jalr	1970(ra) # 8000053e <panic>
    return -1;
    80004d94:	597d                	li	s2,-1
    80004d96:	b765                	j	80004d3e <fileread+0x60>
      return -1;
    80004d98:	597d                	li	s2,-1
    80004d9a:	b755                	j	80004d3e <fileread+0x60>
    80004d9c:	597d                	li	s2,-1
    80004d9e:	b745                	j	80004d3e <fileread+0x60>

0000000080004da0 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004da0:	715d                	addi	sp,sp,-80
    80004da2:	e486                	sd	ra,72(sp)
    80004da4:	e0a2                	sd	s0,64(sp)
    80004da6:	fc26                	sd	s1,56(sp)
    80004da8:	f84a                	sd	s2,48(sp)
    80004daa:	f44e                	sd	s3,40(sp)
    80004dac:	f052                	sd	s4,32(sp)
    80004dae:	ec56                	sd	s5,24(sp)
    80004db0:	e85a                	sd	s6,16(sp)
    80004db2:	e45e                	sd	s7,8(sp)
    80004db4:	e062                	sd	s8,0(sp)
    80004db6:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004db8:	00954783          	lbu	a5,9(a0)
    80004dbc:	10078663          	beqz	a5,80004ec8 <filewrite+0x128>
    80004dc0:	892a                	mv	s2,a0
    80004dc2:	8aae                	mv	s5,a1
    80004dc4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dc6:	411c                	lw	a5,0(a0)
    80004dc8:	4705                	li	a4,1
    80004dca:	02e78263          	beq	a5,a4,80004dee <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004dce:	470d                	li	a4,3
    80004dd0:	02e78663          	beq	a5,a4,80004dfc <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004dd4:	4709                	li	a4,2
    80004dd6:	0ee79163          	bne	a5,a4,80004eb8 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004dda:	0ac05d63          	blez	a2,80004e94 <filewrite+0xf4>
    int i = 0;
    80004dde:	4981                	li	s3,0
    80004de0:	6b05                	lui	s6,0x1
    80004de2:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004de6:	6b85                	lui	s7,0x1
    80004de8:	c00b8b9b          	addiw	s7,s7,-1024
    80004dec:	a861                	j	80004e84 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004dee:	6908                	ld	a0,16(a0)
    80004df0:	00000097          	auipc	ra,0x0
    80004df4:	22e080e7          	jalr	558(ra) # 8000501e <pipewrite>
    80004df8:	8a2a                	mv	s4,a0
    80004dfa:	a045                	j	80004e9a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004dfc:	02451783          	lh	a5,36(a0)
    80004e00:	03079693          	slli	a3,a5,0x30
    80004e04:	92c1                	srli	a3,a3,0x30
    80004e06:	4725                	li	a4,9
    80004e08:	0cd76263          	bltu	a4,a3,80004ecc <filewrite+0x12c>
    80004e0c:	0792                	slli	a5,a5,0x4
    80004e0e:	0001d717          	auipc	a4,0x1d
    80004e12:	fea70713          	addi	a4,a4,-22 # 80021df8 <devsw>
    80004e16:	97ba                	add	a5,a5,a4
    80004e18:	679c                	ld	a5,8(a5)
    80004e1a:	cbdd                	beqz	a5,80004ed0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e1c:	4505                	li	a0,1
    80004e1e:	9782                	jalr	a5
    80004e20:	8a2a                	mv	s4,a0
    80004e22:	a8a5                	j	80004e9a <filewrite+0xfa>
    80004e24:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e28:	00000097          	auipc	ra,0x0
    80004e2c:	8b0080e7          	jalr	-1872(ra) # 800046d8 <begin_op>
      ilock(f->ip);
    80004e30:	01893503          	ld	a0,24(s2)
    80004e34:	fffff097          	auipc	ra,0xfffff
    80004e38:	ee2080e7          	jalr	-286(ra) # 80003d16 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e3c:	8762                	mv	a4,s8
    80004e3e:	02092683          	lw	a3,32(s2)
    80004e42:	01598633          	add	a2,s3,s5
    80004e46:	4585                	li	a1,1
    80004e48:	01893503          	ld	a0,24(s2)
    80004e4c:	fffff097          	auipc	ra,0xfffff
    80004e50:	276080e7          	jalr	630(ra) # 800040c2 <writei>
    80004e54:	84aa                	mv	s1,a0
    80004e56:	00a05763          	blez	a0,80004e64 <filewrite+0xc4>
        f->off += r;
    80004e5a:	02092783          	lw	a5,32(s2)
    80004e5e:	9fa9                	addw	a5,a5,a0
    80004e60:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e64:	01893503          	ld	a0,24(s2)
    80004e68:	fffff097          	auipc	ra,0xfffff
    80004e6c:	f70080e7          	jalr	-144(ra) # 80003dd8 <iunlock>
      end_op();
    80004e70:	00000097          	auipc	ra,0x0
    80004e74:	8e8080e7          	jalr	-1816(ra) # 80004758 <end_op>

      if(r != n1){
    80004e78:	009c1f63          	bne	s8,s1,80004e96 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e7c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e80:	0149db63          	bge	s3,s4,80004e96 <filewrite+0xf6>
      int n1 = n - i;
    80004e84:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004e88:	84be                	mv	s1,a5
    80004e8a:	2781                	sext.w	a5,a5
    80004e8c:	f8fb5ce3          	bge	s6,a5,80004e24 <filewrite+0x84>
    80004e90:	84de                	mv	s1,s7
    80004e92:	bf49                	j	80004e24 <filewrite+0x84>
    int i = 0;
    80004e94:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e96:	013a1f63          	bne	s4,s3,80004eb4 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e9a:	8552                	mv	a0,s4
    80004e9c:	60a6                	ld	ra,72(sp)
    80004e9e:	6406                	ld	s0,64(sp)
    80004ea0:	74e2                	ld	s1,56(sp)
    80004ea2:	7942                	ld	s2,48(sp)
    80004ea4:	79a2                	ld	s3,40(sp)
    80004ea6:	7a02                	ld	s4,32(sp)
    80004ea8:	6ae2                	ld	s5,24(sp)
    80004eaa:	6b42                	ld	s6,16(sp)
    80004eac:	6ba2                	ld	s7,8(sp)
    80004eae:	6c02                	ld	s8,0(sp)
    80004eb0:	6161                	addi	sp,sp,80
    80004eb2:	8082                	ret
    ret = (i == n ? n : -1);
    80004eb4:	5a7d                	li	s4,-1
    80004eb6:	b7d5                	j	80004e9a <filewrite+0xfa>
    panic("filewrite");
    80004eb8:	00004517          	auipc	a0,0x4
    80004ebc:	82850513          	addi	a0,a0,-2008 # 800086e0 <syscalls+0x290>
    80004ec0:	ffffb097          	auipc	ra,0xffffb
    80004ec4:	67e080e7          	jalr	1662(ra) # 8000053e <panic>
    return -1;
    80004ec8:	5a7d                	li	s4,-1
    80004eca:	bfc1                	j	80004e9a <filewrite+0xfa>
      return -1;
    80004ecc:	5a7d                	li	s4,-1
    80004ece:	b7f1                	j	80004e9a <filewrite+0xfa>
    80004ed0:	5a7d                	li	s4,-1
    80004ed2:	b7e1                	j	80004e9a <filewrite+0xfa>

0000000080004ed4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ed4:	7179                	addi	sp,sp,-48
    80004ed6:	f406                	sd	ra,40(sp)
    80004ed8:	f022                	sd	s0,32(sp)
    80004eda:	ec26                	sd	s1,24(sp)
    80004edc:	e84a                	sd	s2,16(sp)
    80004ede:	e44e                	sd	s3,8(sp)
    80004ee0:	e052                	sd	s4,0(sp)
    80004ee2:	1800                	addi	s0,sp,48
    80004ee4:	84aa                	mv	s1,a0
    80004ee6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ee8:	0005b023          	sd	zero,0(a1)
    80004eec:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ef0:	00000097          	auipc	ra,0x0
    80004ef4:	bf8080e7          	jalr	-1032(ra) # 80004ae8 <filealloc>
    80004ef8:	e088                	sd	a0,0(s1)
    80004efa:	c551                	beqz	a0,80004f86 <pipealloc+0xb2>
    80004efc:	00000097          	auipc	ra,0x0
    80004f00:	bec080e7          	jalr	-1044(ra) # 80004ae8 <filealloc>
    80004f04:	00aa3023          	sd	a0,0(s4)
    80004f08:	c92d                	beqz	a0,80004f7a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f0a:	ffffc097          	auipc	ra,0xffffc
    80004f0e:	bdc080e7          	jalr	-1060(ra) # 80000ae6 <kalloc>
    80004f12:	892a                	mv	s2,a0
    80004f14:	c125                	beqz	a0,80004f74 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f16:	4985                	li	s3,1
    80004f18:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f1c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f20:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f24:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f28:	00003597          	auipc	a1,0x3
    80004f2c:	7c858593          	addi	a1,a1,1992 # 800086f0 <syscalls+0x2a0>
    80004f30:	ffffc097          	auipc	ra,0xffffc
    80004f34:	c16080e7          	jalr	-1002(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004f38:	609c                	ld	a5,0(s1)
    80004f3a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f3e:	609c                	ld	a5,0(s1)
    80004f40:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f44:	609c                	ld	a5,0(s1)
    80004f46:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f4a:	609c                	ld	a5,0(s1)
    80004f4c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f50:	000a3783          	ld	a5,0(s4)
    80004f54:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f58:	000a3783          	ld	a5,0(s4)
    80004f5c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f60:	000a3783          	ld	a5,0(s4)
    80004f64:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f68:	000a3783          	ld	a5,0(s4)
    80004f6c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f70:	4501                	li	a0,0
    80004f72:	a025                	j	80004f9a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f74:	6088                	ld	a0,0(s1)
    80004f76:	e501                	bnez	a0,80004f7e <pipealloc+0xaa>
    80004f78:	a039                	j	80004f86 <pipealloc+0xb2>
    80004f7a:	6088                	ld	a0,0(s1)
    80004f7c:	c51d                	beqz	a0,80004faa <pipealloc+0xd6>
    fileclose(*f0);
    80004f7e:	00000097          	auipc	ra,0x0
    80004f82:	c26080e7          	jalr	-986(ra) # 80004ba4 <fileclose>
  if(*f1)
    80004f86:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f8a:	557d                	li	a0,-1
  if(*f1)
    80004f8c:	c799                	beqz	a5,80004f9a <pipealloc+0xc6>
    fileclose(*f1);
    80004f8e:	853e                	mv	a0,a5
    80004f90:	00000097          	auipc	ra,0x0
    80004f94:	c14080e7          	jalr	-1004(ra) # 80004ba4 <fileclose>
  return -1;
    80004f98:	557d                	li	a0,-1
}
    80004f9a:	70a2                	ld	ra,40(sp)
    80004f9c:	7402                	ld	s0,32(sp)
    80004f9e:	64e2                	ld	s1,24(sp)
    80004fa0:	6942                	ld	s2,16(sp)
    80004fa2:	69a2                	ld	s3,8(sp)
    80004fa4:	6a02                	ld	s4,0(sp)
    80004fa6:	6145                	addi	sp,sp,48
    80004fa8:	8082                	ret
  return -1;
    80004faa:	557d                	li	a0,-1
    80004fac:	b7fd                	j	80004f9a <pipealloc+0xc6>

0000000080004fae <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004fae:	1101                	addi	sp,sp,-32
    80004fb0:	ec06                	sd	ra,24(sp)
    80004fb2:	e822                	sd	s0,16(sp)
    80004fb4:	e426                	sd	s1,8(sp)
    80004fb6:	e04a                	sd	s2,0(sp)
    80004fb8:	1000                	addi	s0,sp,32
    80004fba:	84aa                	mv	s1,a0
    80004fbc:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004fbe:	ffffc097          	auipc	ra,0xffffc
    80004fc2:	c18080e7          	jalr	-1000(ra) # 80000bd6 <acquire>
  if(writable){
    80004fc6:	02090d63          	beqz	s2,80005000 <pipeclose+0x52>
    pi->writeopen = 0;
    80004fca:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004fce:	21848513          	addi	a0,s1,536
    80004fd2:	ffffd097          	auipc	ra,0xffffd
    80004fd6:	0f6080e7          	jalr	246(ra) # 800020c8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004fda:	2204b783          	ld	a5,544(s1)
    80004fde:	eb95                	bnez	a5,80005012 <pipeclose+0x64>
    release(&pi->lock);
    80004fe0:	8526                	mv	a0,s1
    80004fe2:	ffffc097          	auipc	ra,0xffffc
    80004fe6:	ca8080e7          	jalr	-856(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004fea:	8526                	mv	a0,s1
    80004fec:	ffffc097          	auipc	ra,0xffffc
    80004ff0:	9fe080e7          	jalr	-1538(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004ff4:	60e2                	ld	ra,24(sp)
    80004ff6:	6442                	ld	s0,16(sp)
    80004ff8:	64a2                	ld	s1,8(sp)
    80004ffa:	6902                	ld	s2,0(sp)
    80004ffc:	6105                	addi	sp,sp,32
    80004ffe:	8082                	ret
    pi->readopen = 0;
    80005000:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005004:	21c48513          	addi	a0,s1,540
    80005008:	ffffd097          	auipc	ra,0xffffd
    8000500c:	0c0080e7          	jalr	192(ra) # 800020c8 <wakeup>
    80005010:	b7e9                	j	80004fda <pipeclose+0x2c>
    release(&pi->lock);
    80005012:	8526                	mv	a0,s1
    80005014:	ffffc097          	auipc	ra,0xffffc
    80005018:	c76080e7          	jalr	-906(ra) # 80000c8a <release>
}
    8000501c:	bfe1                	j	80004ff4 <pipeclose+0x46>

000000008000501e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000501e:	711d                	addi	sp,sp,-96
    80005020:	ec86                	sd	ra,88(sp)
    80005022:	e8a2                	sd	s0,80(sp)
    80005024:	e4a6                	sd	s1,72(sp)
    80005026:	e0ca                	sd	s2,64(sp)
    80005028:	fc4e                	sd	s3,56(sp)
    8000502a:	f852                	sd	s4,48(sp)
    8000502c:	f456                	sd	s5,40(sp)
    8000502e:	f05a                	sd	s6,32(sp)
    80005030:	ec5e                	sd	s7,24(sp)
    80005032:	e862                	sd	s8,16(sp)
    80005034:	1080                	addi	s0,sp,96
    80005036:	84aa                	mv	s1,a0
    80005038:	8aae                	mv	s5,a1
    8000503a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000503c:	ffffd097          	auipc	ra,0xffffd
    80005040:	978080e7          	jalr	-1672(ra) # 800019b4 <myproc>
    80005044:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005046:	8526                	mv	a0,s1
    80005048:	ffffc097          	auipc	ra,0xffffc
    8000504c:	b8e080e7          	jalr	-1138(ra) # 80000bd6 <acquire>
  while(i < n){
    80005050:	0b405663          	blez	s4,800050fc <pipewrite+0xde>
  int i = 0;
    80005054:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005056:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005058:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000505c:	21c48b93          	addi	s7,s1,540
    80005060:	a089                	j	800050a2 <pipewrite+0x84>
      release(&pi->lock);
    80005062:	8526                	mv	a0,s1
    80005064:	ffffc097          	auipc	ra,0xffffc
    80005068:	c26080e7          	jalr	-986(ra) # 80000c8a <release>
      return -1;
    8000506c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000506e:	854a                	mv	a0,s2
    80005070:	60e6                	ld	ra,88(sp)
    80005072:	6446                	ld	s0,80(sp)
    80005074:	64a6                	ld	s1,72(sp)
    80005076:	6906                	ld	s2,64(sp)
    80005078:	79e2                	ld	s3,56(sp)
    8000507a:	7a42                	ld	s4,48(sp)
    8000507c:	7aa2                	ld	s5,40(sp)
    8000507e:	7b02                	ld	s6,32(sp)
    80005080:	6be2                	ld	s7,24(sp)
    80005082:	6c42                	ld	s8,16(sp)
    80005084:	6125                	addi	sp,sp,96
    80005086:	8082                	ret
      wakeup(&pi->nread);
    80005088:	8562                	mv	a0,s8
    8000508a:	ffffd097          	auipc	ra,0xffffd
    8000508e:	03e080e7          	jalr	62(ra) # 800020c8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005092:	85a6                	mv	a1,s1
    80005094:	855e                	mv	a0,s7
    80005096:	ffffd097          	auipc	ra,0xffffd
    8000509a:	fce080e7          	jalr	-50(ra) # 80002064 <sleep>
  while(i < n){
    8000509e:	07495063          	bge	s2,s4,800050fe <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800050a2:	2204a783          	lw	a5,544(s1)
    800050a6:	dfd5                	beqz	a5,80005062 <pipewrite+0x44>
    800050a8:	854e                	mv	a0,s3
    800050aa:	ffffd097          	auipc	ra,0xffffd
    800050ae:	274080e7          	jalr	628(ra) # 8000231e <killed>
    800050b2:	f945                	bnez	a0,80005062 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800050b4:	2184a783          	lw	a5,536(s1)
    800050b8:	21c4a703          	lw	a4,540(s1)
    800050bc:	2007879b          	addiw	a5,a5,512
    800050c0:	fcf704e3          	beq	a4,a5,80005088 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050c4:	4685                	li	a3,1
    800050c6:	01590633          	add	a2,s2,s5
    800050ca:	faf40593          	addi	a1,s0,-81
    800050ce:	0509b503          	ld	a0,80(s3)
    800050d2:	ffffc097          	auipc	ra,0xffffc
    800050d6:	62a080e7          	jalr	1578(ra) # 800016fc <copyin>
    800050da:	03650263          	beq	a0,s6,800050fe <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800050de:	21c4a783          	lw	a5,540(s1)
    800050e2:	0017871b          	addiw	a4,a5,1
    800050e6:	20e4ae23          	sw	a4,540(s1)
    800050ea:	1ff7f793          	andi	a5,a5,511
    800050ee:	97a6                	add	a5,a5,s1
    800050f0:	faf44703          	lbu	a4,-81(s0)
    800050f4:	00e78c23          	sb	a4,24(a5)
      i++;
    800050f8:	2905                	addiw	s2,s2,1
    800050fa:	b755                	j	8000509e <pipewrite+0x80>
  int i = 0;
    800050fc:	4901                	li	s2,0
  wakeup(&pi->nread);
    800050fe:	21848513          	addi	a0,s1,536
    80005102:	ffffd097          	auipc	ra,0xffffd
    80005106:	fc6080e7          	jalr	-58(ra) # 800020c8 <wakeup>
  release(&pi->lock);
    8000510a:	8526                	mv	a0,s1
    8000510c:	ffffc097          	auipc	ra,0xffffc
    80005110:	b7e080e7          	jalr	-1154(ra) # 80000c8a <release>
  return i;
    80005114:	bfa9                	j	8000506e <pipewrite+0x50>

0000000080005116 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005116:	715d                	addi	sp,sp,-80
    80005118:	e486                	sd	ra,72(sp)
    8000511a:	e0a2                	sd	s0,64(sp)
    8000511c:	fc26                	sd	s1,56(sp)
    8000511e:	f84a                	sd	s2,48(sp)
    80005120:	f44e                	sd	s3,40(sp)
    80005122:	f052                	sd	s4,32(sp)
    80005124:	ec56                	sd	s5,24(sp)
    80005126:	e85a                	sd	s6,16(sp)
    80005128:	0880                	addi	s0,sp,80
    8000512a:	84aa                	mv	s1,a0
    8000512c:	892e                	mv	s2,a1
    8000512e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005130:	ffffd097          	auipc	ra,0xffffd
    80005134:	884080e7          	jalr	-1916(ra) # 800019b4 <myproc>
    80005138:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000513a:	8526                	mv	a0,s1
    8000513c:	ffffc097          	auipc	ra,0xffffc
    80005140:	a9a080e7          	jalr	-1382(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005144:	2184a703          	lw	a4,536(s1)
    80005148:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000514c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005150:	02f71763          	bne	a4,a5,8000517e <piperead+0x68>
    80005154:	2244a783          	lw	a5,548(s1)
    80005158:	c39d                	beqz	a5,8000517e <piperead+0x68>
    if(killed(pr)){
    8000515a:	8552                	mv	a0,s4
    8000515c:	ffffd097          	auipc	ra,0xffffd
    80005160:	1c2080e7          	jalr	450(ra) # 8000231e <killed>
    80005164:	e941                	bnez	a0,800051f4 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005166:	85a6                	mv	a1,s1
    80005168:	854e                	mv	a0,s3
    8000516a:	ffffd097          	auipc	ra,0xffffd
    8000516e:	efa080e7          	jalr	-262(ra) # 80002064 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005172:	2184a703          	lw	a4,536(s1)
    80005176:	21c4a783          	lw	a5,540(s1)
    8000517a:	fcf70de3          	beq	a4,a5,80005154 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000517e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005180:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005182:	05505363          	blez	s5,800051c8 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80005186:	2184a783          	lw	a5,536(s1)
    8000518a:	21c4a703          	lw	a4,540(s1)
    8000518e:	02f70d63          	beq	a4,a5,800051c8 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005192:	0017871b          	addiw	a4,a5,1
    80005196:	20e4ac23          	sw	a4,536(s1)
    8000519a:	1ff7f793          	andi	a5,a5,511
    8000519e:	97a6                	add	a5,a5,s1
    800051a0:	0187c783          	lbu	a5,24(a5)
    800051a4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051a8:	4685                	li	a3,1
    800051aa:	fbf40613          	addi	a2,s0,-65
    800051ae:	85ca                	mv	a1,s2
    800051b0:	050a3503          	ld	a0,80(s4)
    800051b4:	ffffc097          	auipc	ra,0xffffc
    800051b8:	4bc080e7          	jalr	1212(ra) # 80001670 <copyout>
    800051bc:	01650663          	beq	a0,s6,800051c8 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051c0:	2985                	addiw	s3,s3,1
    800051c2:	0905                	addi	s2,s2,1
    800051c4:	fd3a91e3          	bne	s5,s3,80005186 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800051c8:	21c48513          	addi	a0,s1,540
    800051cc:	ffffd097          	auipc	ra,0xffffd
    800051d0:	efc080e7          	jalr	-260(ra) # 800020c8 <wakeup>
  release(&pi->lock);
    800051d4:	8526                	mv	a0,s1
    800051d6:	ffffc097          	auipc	ra,0xffffc
    800051da:	ab4080e7          	jalr	-1356(ra) # 80000c8a <release>
  return i;
}
    800051de:	854e                	mv	a0,s3
    800051e0:	60a6                	ld	ra,72(sp)
    800051e2:	6406                	ld	s0,64(sp)
    800051e4:	74e2                	ld	s1,56(sp)
    800051e6:	7942                	ld	s2,48(sp)
    800051e8:	79a2                	ld	s3,40(sp)
    800051ea:	7a02                	ld	s4,32(sp)
    800051ec:	6ae2                	ld	s5,24(sp)
    800051ee:	6b42                	ld	s6,16(sp)
    800051f0:	6161                	addi	sp,sp,80
    800051f2:	8082                	ret
      release(&pi->lock);
    800051f4:	8526                	mv	a0,s1
    800051f6:	ffffc097          	auipc	ra,0xffffc
    800051fa:	a94080e7          	jalr	-1388(ra) # 80000c8a <release>
      return -1;
    800051fe:	59fd                	li	s3,-1
    80005200:	bff9                	j	800051de <piperead+0xc8>

0000000080005202 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005202:	1141                	addi	sp,sp,-16
    80005204:	e422                	sd	s0,8(sp)
    80005206:	0800                	addi	s0,sp,16
    80005208:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000520a:	8905                	andi	a0,a0,1
    8000520c:	c111                	beqz	a0,80005210 <flags2perm+0xe>
      perm = PTE_X;
    8000520e:	4521                	li	a0,8
    if(flags & 0x2)
    80005210:	8b89                	andi	a5,a5,2
    80005212:	c399                	beqz	a5,80005218 <flags2perm+0x16>
      perm |= PTE_W;
    80005214:	00456513          	ori	a0,a0,4
    return perm;
}
    80005218:	6422                	ld	s0,8(sp)
    8000521a:	0141                	addi	sp,sp,16
    8000521c:	8082                	ret

000000008000521e <exec>:

int
exec(char *path, char **argv)
{
    8000521e:	de010113          	addi	sp,sp,-544
    80005222:	20113c23          	sd	ra,536(sp)
    80005226:	20813823          	sd	s0,528(sp)
    8000522a:	20913423          	sd	s1,520(sp)
    8000522e:	21213023          	sd	s2,512(sp)
    80005232:	ffce                	sd	s3,504(sp)
    80005234:	fbd2                	sd	s4,496(sp)
    80005236:	f7d6                	sd	s5,488(sp)
    80005238:	f3da                	sd	s6,480(sp)
    8000523a:	efde                	sd	s7,472(sp)
    8000523c:	ebe2                	sd	s8,464(sp)
    8000523e:	e7e6                	sd	s9,456(sp)
    80005240:	e3ea                	sd	s10,448(sp)
    80005242:	ff6e                	sd	s11,440(sp)
    80005244:	1400                	addi	s0,sp,544
    80005246:	892a                	mv	s2,a0
    80005248:	dea43423          	sd	a0,-536(s0)
    8000524c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005250:	ffffc097          	auipc	ra,0xffffc
    80005254:	764080e7          	jalr	1892(ra) # 800019b4 <myproc>
    80005258:	84aa                	mv	s1,a0

  begin_op();
    8000525a:	fffff097          	auipc	ra,0xfffff
    8000525e:	47e080e7          	jalr	1150(ra) # 800046d8 <begin_op>

  if((ip = namei(path)) == 0){
    80005262:	854a                	mv	a0,s2
    80005264:	fffff097          	auipc	ra,0xfffff
    80005268:	258080e7          	jalr	600(ra) # 800044bc <namei>
    8000526c:	c93d                	beqz	a0,800052e2 <exec+0xc4>
    8000526e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005270:	fffff097          	auipc	ra,0xfffff
    80005274:	aa6080e7          	jalr	-1370(ra) # 80003d16 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005278:	04000713          	li	a4,64
    8000527c:	4681                	li	a3,0
    8000527e:	e5040613          	addi	a2,s0,-432
    80005282:	4581                	li	a1,0
    80005284:	8556                	mv	a0,s5
    80005286:	fffff097          	auipc	ra,0xfffff
    8000528a:	d44080e7          	jalr	-700(ra) # 80003fca <readi>
    8000528e:	04000793          	li	a5,64
    80005292:	00f51a63          	bne	a0,a5,800052a6 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005296:	e5042703          	lw	a4,-432(s0)
    8000529a:	464c47b7          	lui	a5,0x464c4
    8000529e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800052a2:	04f70663          	beq	a4,a5,800052ee <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800052a6:	8556                	mv	a0,s5
    800052a8:	fffff097          	auipc	ra,0xfffff
    800052ac:	cd0080e7          	jalr	-816(ra) # 80003f78 <iunlockput>
    end_op();
    800052b0:	fffff097          	auipc	ra,0xfffff
    800052b4:	4a8080e7          	jalr	1192(ra) # 80004758 <end_op>
  }
  return -1;
    800052b8:	557d                	li	a0,-1
}
    800052ba:	21813083          	ld	ra,536(sp)
    800052be:	21013403          	ld	s0,528(sp)
    800052c2:	20813483          	ld	s1,520(sp)
    800052c6:	20013903          	ld	s2,512(sp)
    800052ca:	79fe                	ld	s3,504(sp)
    800052cc:	7a5e                	ld	s4,496(sp)
    800052ce:	7abe                	ld	s5,488(sp)
    800052d0:	7b1e                	ld	s6,480(sp)
    800052d2:	6bfe                	ld	s7,472(sp)
    800052d4:	6c5e                	ld	s8,464(sp)
    800052d6:	6cbe                	ld	s9,456(sp)
    800052d8:	6d1e                	ld	s10,448(sp)
    800052da:	7dfa                	ld	s11,440(sp)
    800052dc:	22010113          	addi	sp,sp,544
    800052e0:	8082                	ret
    end_op();
    800052e2:	fffff097          	auipc	ra,0xfffff
    800052e6:	476080e7          	jalr	1142(ra) # 80004758 <end_op>
    return -1;
    800052ea:	557d                	li	a0,-1
    800052ec:	b7f9                	j	800052ba <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800052ee:	8526                	mv	a0,s1
    800052f0:	ffffc097          	auipc	ra,0xffffc
    800052f4:	788080e7          	jalr	1928(ra) # 80001a78 <proc_pagetable>
    800052f8:	8b2a                	mv	s6,a0
    800052fa:	d555                	beqz	a0,800052a6 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052fc:	e7042783          	lw	a5,-400(s0)
    80005300:	e8845703          	lhu	a4,-376(s0)
    80005304:	c735                	beqz	a4,80005370 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005306:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005308:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    8000530c:	6a05                	lui	s4,0x1
    8000530e:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005312:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005316:	6d85                	lui	s11,0x1
    80005318:	7d7d                	lui	s10,0xfffff
    8000531a:	a481                	j	8000555a <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000531c:	00003517          	auipc	a0,0x3
    80005320:	3dc50513          	addi	a0,a0,988 # 800086f8 <syscalls+0x2a8>
    80005324:	ffffb097          	auipc	ra,0xffffb
    80005328:	21a080e7          	jalr	538(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000532c:	874a                	mv	a4,s2
    8000532e:	009c86bb          	addw	a3,s9,s1
    80005332:	4581                	li	a1,0
    80005334:	8556                	mv	a0,s5
    80005336:	fffff097          	auipc	ra,0xfffff
    8000533a:	c94080e7          	jalr	-876(ra) # 80003fca <readi>
    8000533e:	2501                	sext.w	a0,a0
    80005340:	1aa91a63          	bne	s2,a0,800054f4 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80005344:	009d84bb          	addw	s1,s11,s1
    80005348:	013d09bb          	addw	s3,s10,s3
    8000534c:	1f74f763          	bgeu	s1,s7,8000553a <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80005350:	02049593          	slli	a1,s1,0x20
    80005354:	9181                	srli	a1,a1,0x20
    80005356:	95e2                	add	a1,a1,s8
    80005358:	855a                	mv	a0,s6
    8000535a:	ffffc097          	auipc	ra,0xffffc
    8000535e:	d0a080e7          	jalr	-758(ra) # 80001064 <walkaddr>
    80005362:	862a                	mv	a2,a0
    if(pa == 0)
    80005364:	dd45                	beqz	a0,8000531c <exec+0xfe>
      n = PGSIZE;
    80005366:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005368:	fd49f2e3          	bgeu	s3,s4,8000532c <exec+0x10e>
      n = sz - i;
    8000536c:	894e                	mv	s2,s3
    8000536e:	bf7d                	j	8000532c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005370:	4901                	li	s2,0
  iunlockput(ip);
    80005372:	8556                	mv	a0,s5
    80005374:	fffff097          	auipc	ra,0xfffff
    80005378:	c04080e7          	jalr	-1020(ra) # 80003f78 <iunlockput>
  end_op();
    8000537c:	fffff097          	auipc	ra,0xfffff
    80005380:	3dc080e7          	jalr	988(ra) # 80004758 <end_op>
  p = myproc();
    80005384:	ffffc097          	auipc	ra,0xffffc
    80005388:	630080e7          	jalr	1584(ra) # 800019b4 <myproc>
    8000538c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000538e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005392:	6785                	lui	a5,0x1
    80005394:	17fd                	addi	a5,a5,-1
    80005396:	993e                	add	s2,s2,a5
    80005398:	77fd                	lui	a5,0xfffff
    8000539a:	00f977b3          	and	a5,s2,a5
    8000539e:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800053a2:	4691                	li	a3,4
    800053a4:	6609                	lui	a2,0x2
    800053a6:	963e                	add	a2,a2,a5
    800053a8:	85be                	mv	a1,a5
    800053aa:	855a                	mv	a0,s6
    800053ac:	ffffc097          	auipc	ra,0xffffc
    800053b0:	06c080e7          	jalr	108(ra) # 80001418 <uvmalloc>
    800053b4:	8c2a                	mv	s8,a0
  ip = 0;
    800053b6:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800053b8:	12050e63          	beqz	a0,800054f4 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800053bc:	75f9                	lui	a1,0xffffe
    800053be:	95aa                	add	a1,a1,a0
    800053c0:	855a                	mv	a0,s6
    800053c2:	ffffc097          	auipc	ra,0xffffc
    800053c6:	27c080e7          	jalr	636(ra) # 8000163e <uvmclear>
  stackbase = sp - PGSIZE;
    800053ca:	7afd                	lui	s5,0xfffff
    800053cc:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800053ce:	df043783          	ld	a5,-528(s0)
    800053d2:	6388                	ld	a0,0(a5)
    800053d4:	c925                	beqz	a0,80005444 <exec+0x226>
    800053d6:	e9040993          	addi	s3,s0,-368
    800053da:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800053de:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800053e0:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800053e2:	ffffc097          	auipc	ra,0xffffc
    800053e6:	a6c080e7          	jalr	-1428(ra) # 80000e4e <strlen>
    800053ea:	0015079b          	addiw	a5,a0,1
    800053ee:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800053f2:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800053f6:	13596663          	bltu	s2,s5,80005522 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800053fa:	df043d83          	ld	s11,-528(s0)
    800053fe:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005402:	8552                	mv	a0,s4
    80005404:	ffffc097          	auipc	ra,0xffffc
    80005408:	a4a080e7          	jalr	-1462(ra) # 80000e4e <strlen>
    8000540c:	0015069b          	addiw	a3,a0,1
    80005410:	8652                	mv	a2,s4
    80005412:	85ca                	mv	a1,s2
    80005414:	855a                	mv	a0,s6
    80005416:	ffffc097          	auipc	ra,0xffffc
    8000541a:	25a080e7          	jalr	602(ra) # 80001670 <copyout>
    8000541e:	10054663          	bltz	a0,8000552a <exec+0x30c>
    ustack[argc] = sp;
    80005422:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005426:	0485                	addi	s1,s1,1
    80005428:	008d8793          	addi	a5,s11,8
    8000542c:	def43823          	sd	a5,-528(s0)
    80005430:	008db503          	ld	a0,8(s11)
    80005434:	c911                	beqz	a0,80005448 <exec+0x22a>
    if(argc >= MAXARG)
    80005436:	09a1                	addi	s3,s3,8
    80005438:	fb3c95e3          	bne	s9,s3,800053e2 <exec+0x1c4>
  sz = sz1;
    8000543c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005440:	4a81                	li	s5,0
    80005442:	a84d                	j	800054f4 <exec+0x2d6>
  sp = sz;
    80005444:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005446:	4481                	li	s1,0
  ustack[argc] = 0;
    80005448:	00349793          	slli	a5,s1,0x3
    8000544c:	f9040713          	addi	a4,s0,-112
    80005450:	97ba                	add	a5,a5,a4
    80005452:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdbf70>
  sp -= (argc+1) * sizeof(uint64);
    80005456:	00148693          	addi	a3,s1,1
    8000545a:	068e                	slli	a3,a3,0x3
    8000545c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005460:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005464:	01597663          	bgeu	s2,s5,80005470 <exec+0x252>
  sz = sz1;
    80005468:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000546c:	4a81                	li	s5,0
    8000546e:	a059                	j	800054f4 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005470:	e9040613          	addi	a2,s0,-368
    80005474:	85ca                	mv	a1,s2
    80005476:	855a                	mv	a0,s6
    80005478:	ffffc097          	auipc	ra,0xffffc
    8000547c:	1f8080e7          	jalr	504(ra) # 80001670 <copyout>
    80005480:	0a054963          	bltz	a0,80005532 <exec+0x314>
  p->trapframe->a1 = sp;
    80005484:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005488:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000548c:	de843783          	ld	a5,-536(s0)
    80005490:	0007c703          	lbu	a4,0(a5)
    80005494:	cf11                	beqz	a4,800054b0 <exec+0x292>
    80005496:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005498:	02f00693          	li	a3,47
    8000549c:	a039                	j	800054aa <exec+0x28c>
      last = s+1;
    8000549e:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800054a2:	0785                	addi	a5,a5,1
    800054a4:	fff7c703          	lbu	a4,-1(a5)
    800054a8:	c701                	beqz	a4,800054b0 <exec+0x292>
    if(*s == '/')
    800054aa:	fed71ce3          	bne	a4,a3,800054a2 <exec+0x284>
    800054ae:	bfc5                	j	8000549e <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    800054b0:	4641                	li	a2,16
    800054b2:	de843583          	ld	a1,-536(s0)
    800054b6:	158b8513          	addi	a0,s7,344
    800054ba:	ffffc097          	auipc	ra,0xffffc
    800054be:	962080e7          	jalr	-1694(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    800054c2:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800054c6:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800054ca:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800054ce:	058bb783          	ld	a5,88(s7)
    800054d2:	e6843703          	ld	a4,-408(s0)
    800054d6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800054d8:	058bb783          	ld	a5,88(s7)
    800054dc:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800054e0:	85ea                	mv	a1,s10
    800054e2:	ffffc097          	auipc	ra,0xffffc
    800054e6:	632080e7          	jalr	1586(ra) # 80001b14 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800054ea:	0004851b          	sext.w	a0,s1
    800054ee:	b3f1                	j	800052ba <exec+0x9c>
    800054f0:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800054f4:	df843583          	ld	a1,-520(s0)
    800054f8:	855a                	mv	a0,s6
    800054fa:	ffffc097          	auipc	ra,0xffffc
    800054fe:	61a080e7          	jalr	1562(ra) # 80001b14 <proc_freepagetable>
  if(ip){
    80005502:	da0a92e3          	bnez	s5,800052a6 <exec+0x88>
  return -1;
    80005506:	557d                	li	a0,-1
    80005508:	bb4d                	j	800052ba <exec+0x9c>
    8000550a:	df243c23          	sd	s2,-520(s0)
    8000550e:	b7dd                	j	800054f4 <exec+0x2d6>
    80005510:	df243c23          	sd	s2,-520(s0)
    80005514:	b7c5                	j	800054f4 <exec+0x2d6>
    80005516:	df243c23          	sd	s2,-520(s0)
    8000551a:	bfe9                	j	800054f4 <exec+0x2d6>
    8000551c:	df243c23          	sd	s2,-520(s0)
    80005520:	bfd1                	j	800054f4 <exec+0x2d6>
  sz = sz1;
    80005522:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005526:	4a81                	li	s5,0
    80005528:	b7f1                	j	800054f4 <exec+0x2d6>
  sz = sz1;
    8000552a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000552e:	4a81                	li	s5,0
    80005530:	b7d1                	j	800054f4 <exec+0x2d6>
  sz = sz1;
    80005532:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005536:	4a81                	li	s5,0
    80005538:	bf75                	j	800054f4 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000553a:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000553e:	e0843783          	ld	a5,-504(s0)
    80005542:	0017869b          	addiw	a3,a5,1
    80005546:	e0d43423          	sd	a3,-504(s0)
    8000554a:	e0043783          	ld	a5,-512(s0)
    8000554e:	0387879b          	addiw	a5,a5,56
    80005552:	e8845703          	lhu	a4,-376(s0)
    80005556:	e0e6dee3          	bge	a3,a4,80005372 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000555a:	2781                	sext.w	a5,a5
    8000555c:	e0f43023          	sd	a5,-512(s0)
    80005560:	03800713          	li	a4,56
    80005564:	86be                	mv	a3,a5
    80005566:	e1840613          	addi	a2,s0,-488
    8000556a:	4581                	li	a1,0
    8000556c:	8556                	mv	a0,s5
    8000556e:	fffff097          	auipc	ra,0xfffff
    80005572:	a5c080e7          	jalr	-1444(ra) # 80003fca <readi>
    80005576:	03800793          	li	a5,56
    8000557a:	f6f51be3          	bne	a0,a5,800054f0 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    8000557e:	e1842783          	lw	a5,-488(s0)
    80005582:	4705                	li	a4,1
    80005584:	fae79de3          	bne	a5,a4,8000553e <exec+0x320>
    if(ph.memsz < ph.filesz)
    80005588:	e4043483          	ld	s1,-448(s0)
    8000558c:	e3843783          	ld	a5,-456(s0)
    80005590:	f6f4ede3          	bltu	s1,a5,8000550a <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005594:	e2843783          	ld	a5,-472(s0)
    80005598:	94be                	add	s1,s1,a5
    8000559a:	f6f4ebe3          	bltu	s1,a5,80005510 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    8000559e:	de043703          	ld	a4,-544(s0)
    800055a2:	8ff9                	and	a5,a5,a4
    800055a4:	fbad                	bnez	a5,80005516 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800055a6:	e1c42503          	lw	a0,-484(s0)
    800055aa:	00000097          	auipc	ra,0x0
    800055ae:	c58080e7          	jalr	-936(ra) # 80005202 <flags2perm>
    800055b2:	86aa                	mv	a3,a0
    800055b4:	8626                	mv	a2,s1
    800055b6:	85ca                	mv	a1,s2
    800055b8:	855a                	mv	a0,s6
    800055ba:	ffffc097          	auipc	ra,0xffffc
    800055be:	e5e080e7          	jalr	-418(ra) # 80001418 <uvmalloc>
    800055c2:	dea43c23          	sd	a0,-520(s0)
    800055c6:	d939                	beqz	a0,8000551c <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800055c8:	e2843c03          	ld	s8,-472(s0)
    800055cc:	e2042c83          	lw	s9,-480(s0)
    800055d0:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800055d4:	f60b83e3          	beqz	s7,8000553a <exec+0x31c>
    800055d8:	89de                	mv	s3,s7
    800055da:	4481                	li	s1,0
    800055dc:	bb95                	j	80005350 <exec+0x132>

00000000800055de <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800055de:	7179                	addi	sp,sp,-48
    800055e0:	f406                	sd	ra,40(sp)
    800055e2:	f022                	sd	s0,32(sp)
    800055e4:	ec26                	sd	s1,24(sp)
    800055e6:	e84a                	sd	s2,16(sp)
    800055e8:	1800                	addi	s0,sp,48
    800055ea:	892e                	mv	s2,a1
    800055ec:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800055ee:	fdc40593          	addi	a1,s0,-36
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	a98080e7          	jalr	-1384(ra) # 8000308a <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800055fa:	fdc42703          	lw	a4,-36(s0)
    800055fe:	47bd                	li	a5,15
    80005600:	02e7eb63          	bltu	a5,a4,80005636 <argfd+0x58>
    80005604:	ffffc097          	auipc	ra,0xffffc
    80005608:	3b0080e7          	jalr	944(ra) # 800019b4 <myproc>
    8000560c:	fdc42703          	lw	a4,-36(s0)
    80005610:	01a70793          	addi	a5,a4,26
    80005614:	078e                	slli	a5,a5,0x3
    80005616:	953e                	add	a0,a0,a5
    80005618:	611c                	ld	a5,0(a0)
    8000561a:	c385                	beqz	a5,8000563a <argfd+0x5c>
    return -1;
  if(pfd)
    8000561c:	00090463          	beqz	s2,80005624 <argfd+0x46>
    *pfd = fd;
    80005620:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005624:	4501                	li	a0,0
  if(pf)
    80005626:	c091                	beqz	s1,8000562a <argfd+0x4c>
    *pf = f;
    80005628:	e09c                	sd	a5,0(s1)
}
    8000562a:	70a2                	ld	ra,40(sp)
    8000562c:	7402                	ld	s0,32(sp)
    8000562e:	64e2                	ld	s1,24(sp)
    80005630:	6942                	ld	s2,16(sp)
    80005632:	6145                	addi	sp,sp,48
    80005634:	8082                	ret
    return -1;
    80005636:	557d                	li	a0,-1
    80005638:	bfcd                	j	8000562a <argfd+0x4c>
    8000563a:	557d                	li	a0,-1
    8000563c:	b7fd                	j	8000562a <argfd+0x4c>

000000008000563e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000563e:	1101                	addi	sp,sp,-32
    80005640:	ec06                	sd	ra,24(sp)
    80005642:	e822                	sd	s0,16(sp)
    80005644:	e426                	sd	s1,8(sp)
    80005646:	1000                	addi	s0,sp,32
    80005648:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000564a:	ffffc097          	auipc	ra,0xffffc
    8000564e:	36a080e7          	jalr	874(ra) # 800019b4 <myproc>
    80005652:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005654:	0d050793          	addi	a5,a0,208
    80005658:	4501                	li	a0,0
    8000565a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000565c:	6398                	ld	a4,0(a5)
    8000565e:	cb19                	beqz	a4,80005674 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005660:	2505                	addiw	a0,a0,1
    80005662:	07a1                	addi	a5,a5,8
    80005664:	fed51ce3          	bne	a0,a3,8000565c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005668:	557d                	li	a0,-1
}
    8000566a:	60e2                	ld	ra,24(sp)
    8000566c:	6442                	ld	s0,16(sp)
    8000566e:	64a2                	ld	s1,8(sp)
    80005670:	6105                	addi	sp,sp,32
    80005672:	8082                	ret
      p->ofile[fd] = f;
    80005674:	01a50793          	addi	a5,a0,26
    80005678:	078e                	slli	a5,a5,0x3
    8000567a:	963e                	add	a2,a2,a5
    8000567c:	e204                	sd	s1,0(a2)
      return fd;
    8000567e:	b7f5                	j	8000566a <fdalloc+0x2c>

0000000080005680 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005680:	715d                	addi	sp,sp,-80
    80005682:	e486                	sd	ra,72(sp)
    80005684:	e0a2                	sd	s0,64(sp)
    80005686:	fc26                	sd	s1,56(sp)
    80005688:	f84a                	sd	s2,48(sp)
    8000568a:	f44e                	sd	s3,40(sp)
    8000568c:	f052                	sd	s4,32(sp)
    8000568e:	ec56                	sd	s5,24(sp)
    80005690:	e85a                	sd	s6,16(sp)
    80005692:	0880                	addi	s0,sp,80
    80005694:	8b2e                	mv	s6,a1
    80005696:	89b2                	mv	s3,a2
    80005698:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000569a:	fb040593          	addi	a1,s0,-80
    8000569e:	fffff097          	auipc	ra,0xfffff
    800056a2:	e3c080e7          	jalr	-452(ra) # 800044da <nameiparent>
    800056a6:	84aa                	mv	s1,a0
    800056a8:	14050f63          	beqz	a0,80005806 <create+0x186>
    return 0;

  ilock(dp);
    800056ac:	ffffe097          	auipc	ra,0xffffe
    800056b0:	66a080e7          	jalr	1642(ra) # 80003d16 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800056b4:	4601                	li	a2,0
    800056b6:	fb040593          	addi	a1,s0,-80
    800056ba:	8526                	mv	a0,s1
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	b3e080e7          	jalr	-1218(ra) # 800041fa <dirlookup>
    800056c4:	8aaa                	mv	s5,a0
    800056c6:	c931                	beqz	a0,8000571a <create+0x9a>
    iunlockput(dp);
    800056c8:	8526                	mv	a0,s1
    800056ca:	fffff097          	auipc	ra,0xfffff
    800056ce:	8ae080e7          	jalr	-1874(ra) # 80003f78 <iunlockput>
    ilock(ip);
    800056d2:	8556                	mv	a0,s5
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	642080e7          	jalr	1602(ra) # 80003d16 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800056dc:	000b059b          	sext.w	a1,s6
    800056e0:	4789                	li	a5,2
    800056e2:	02f59563          	bne	a1,a5,8000570c <create+0x8c>
    800056e6:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc0b4>
    800056ea:	37f9                	addiw	a5,a5,-2
    800056ec:	17c2                	slli	a5,a5,0x30
    800056ee:	93c1                	srli	a5,a5,0x30
    800056f0:	4705                	li	a4,1
    800056f2:	00f76d63          	bltu	a4,a5,8000570c <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800056f6:	8556                	mv	a0,s5
    800056f8:	60a6                	ld	ra,72(sp)
    800056fa:	6406                	ld	s0,64(sp)
    800056fc:	74e2                	ld	s1,56(sp)
    800056fe:	7942                	ld	s2,48(sp)
    80005700:	79a2                	ld	s3,40(sp)
    80005702:	7a02                	ld	s4,32(sp)
    80005704:	6ae2                	ld	s5,24(sp)
    80005706:	6b42                	ld	s6,16(sp)
    80005708:	6161                	addi	sp,sp,80
    8000570a:	8082                	ret
    iunlockput(ip);
    8000570c:	8556                	mv	a0,s5
    8000570e:	fffff097          	auipc	ra,0xfffff
    80005712:	86a080e7          	jalr	-1942(ra) # 80003f78 <iunlockput>
    return 0;
    80005716:	4a81                	li	s5,0
    80005718:	bff9                	j	800056f6 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000571a:	85da                	mv	a1,s6
    8000571c:	4088                	lw	a0,0(s1)
    8000571e:	ffffe097          	auipc	ra,0xffffe
    80005722:	45c080e7          	jalr	1116(ra) # 80003b7a <ialloc>
    80005726:	8a2a                	mv	s4,a0
    80005728:	c539                	beqz	a0,80005776 <create+0xf6>
  ilock(ip);
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	5ec080e7          	jalr	1516(ra) # 80003d16 <ilock>
  ip->major = major;
    80005732:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005736:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000573a:	4905                	li	s2,1
    8000573c:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005740:	8552                	mv	a0,s4
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	50a080e7          	jalr	1290(ra) # 80003c4c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000574a:	000b059b          	sext.w	a1,s6
    8000574e:	03258b63          	beq	a1,s2,80005784 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005752:	004a2603          	lw	a2,4(s4)
    80005756:	fb040593          	addi	a1,s0,-80
    8000575a:	8526                	mv	a0,s1
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	cae080e7          	jalr	-850(ra) # 8000440a <dirlink>
    80005764:	06054f63          	bltz	a0,800057e2 <create+0x162>
  iunlockput(dp);
    80005768:	8526                	mv	a0,s1
    8000576a:	fffff097          	auipc	ra,0xfffff
    8000576e:	80e080e7          	jalr	-2034(ra) # 80003f78 <iunlockput>
  return ip;
    80005772:	8ad2                	mv	s5,s4
    80005774:	b749                	j	800056f6 <create+0x76>
    iunlockput(dp);
    80005776:	8526                	mv	a0,s1
    80005778:	fffff097          	auipc	ra,0xfffff
    8000577c:	800080e7          	jalr	-2048(ra) # 80003f78 <iunlockput>
    return 0;
    80005780:	8ad2                	mv	s5,s4
    80005782:	bf95                	j	800056f6 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005784:	004a2603          	lw	a2,4(s4)
    80005788:	00003597          	auipc	a1,0x3
    8000578c:	f9058593          	addi	a1,a1,-112 # 80008718 <syscalls+0x2c8>
    80005790:	8552                	mv	a0,s4
    80005792:	fffff097          	auipc	ra,0xfffff
    80005796:	c78080e7          	jalr	-904(ra) # 8000440a <dirlink>
    8000579a:	04054463          	bltz	a0,800057e2 <create+0x162>
    8000579e:	40d0                	lw	a2,4(s1)
    800057a0:	00003597          	auipc	a1,0x3
    800057a4:	f8058593          	addi	a1,a1,-128 # 80008720 <syscalls+0x2d0>
    800057a8:	8552                	mv	a0,s4
    800057aa:	fffff097          	auipc	ra,0xfffff
    800057ae:	c60080e7          	jalr	-928(ra) # 8000440a <dirlink>
    800057b2:	02054863          	bltz	a0,800057e2 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800057b6:	004a2603          	lw	a2,4(s4)
    800057ba:	fb040593          	addi	a1,s0,-80
    800057be:	8526                	mv	a0,s1
    800057c0:	fffff097          	auipc	ra,0xfffff
    800057c4:	c4a080e7          	jalr	-950(ra) # 8000440a <dirlink>
    800057c8:	00054d63          	bltz	a0,800057e2 <create+0x162>
    dp->nlink++;  // for ".."
    800057cc:	04a4d783          	lhu	a5,74(s1)
    800057d0:	2785                	addiw	a5,a5,1
    800057d2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057d6:	8526                	mv	a0,s1
    800057d8:	ffffe097          	auipc	ra,0xffffe
    800057dc:	474080e7          	jalr	1140(ra) # 80003c4c <iupdate>
    800057e0:	b761                	j	80005768 <create+0xe8>
  ip->nlink = 0;
    800057e2:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800057e6:	8552                	mv	a0,s4
    800057e8:	ffffe097          	auipc	ra,0xffffe
    800057ec:	464080e7          	jalr	1124(ra) # 80003c4c <iupdate>
  iunlockput(ip);
    800057f0:	8552                	mv	a0,s4
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	786080e7          	jalr	1926(ra) # 80003f78 <iunlockput>
  iunlockput(dp);
    800057fa:	8526                	mv	a0,s1
    800057fc:	ffffe097          	auipc	ra,0xffffe
    80005800:	77c080e7          	jalr	1916(ra) # 80003f78 <iunlockput>
  return 0;
    80005804:	bdcd                	j	800056f6 <create+0x76>
    return 0;
    80005806:	8aaa                	mv	s5,a0
    80005808:	b5fd                	j	800056f6 <create+0x76>

000000008000580a <sys_dup>:
{
    8000580a:	7179                	addi	sp,sp,-48
    8000580c:	f406                	sd	ra,40(sp)
    8000580e:	f022                	sd	s0,32(sp)
    80005810:	ec26                	sd	s1,24(sp)
    80005812:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005814:	fd840613          	addi	a2,s0,-40
    80005818:	4581                	li	a1,0
    8000581a:	4501                	li	a0,0
    8000581c:	00000097          	auipc	ra,0x0
    80005820:	dc2080e7          	jalr	-574(ra) # 800055de <argfd>
    return -1;
    80005824:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005826:	02054363          	bltz	a0,8000584c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000582a:	fd843503          	ld	a0,-40(s0)
    8000582e:	00000097          	auipc	ra,0x0
    80005832:	e10080e7          	jalr	-496(ra) # 8000563e <fdalloc>
    80005836:	84aa                	mv	s1,a0
    return -1;
    80005838:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000583a:	00054963          	bltz	a0,8000584c <sys_dup+0x42>
  filedup(f);
    8000583e:	fd843503          	ld	a0,-40(s0)
    80005842:	fffff097          	auipc	ra,0xfffff
    80005846:	310080e7          	jalr	784(ra) # 80004b52 <filedup>
  return fd;
    8000584a:	87a6                	mv	a5,s1
}
    8000584c:	853e                	mv	a0,a5
    8000584e:	70a2                	ld	ra,40(sp)
    80005850:	7402                	ld	s0,32(sp)
    80005852:	64e2                	ld	s1,24(sp)
    80005854:	6145                	addi	sp,sp,48
    80005856:	8082                	ret

0000000080005858 <sys_read>:
{
    80005858:	7179                	addi	sp,sp,-48
    8000585a:	f406                	sd	ra,40(sp)
    8000585c:	f022                	sd	s0,32(sp)
    8000585e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005860:	fd840593          	addi	a1,s0,-40
    80005864:	4505                	li	a0,1
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	844080e7          	jalr	-1980(ra) # 800030aa <argaddr>
  argint(2, &n);
    8000586e:	fe440593          	addi	a1,s0,-28
    80005872:	4509                	li	a0,2
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	816080e7          	jalr	-2026(ra) # 8000308a <argint>
  if(argfd(0, 0, &f) < 0)
    8000587c:	fe840613          	addi	a2,s0,-24
    80005880:	4581                	li	a1,0
    80005882:	4501                	li	a0,0
    80005884:	00000097          	auipc	ra,0x0
    80005888:	d5a080e7          	jalr	-678(ra) # 800055de <argfd>
    8000588c:	87aa                	mv	a5,a0
    return -1;
    8000588e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005890:	0007cc63          	bltz	a5,800058a8 <sys_read+0x50>
  return fileread(f, p, n);
    80005894:	fe442603          	lw	a2,-28(s0)
    80005898:	fd843583          	ld	a1,-40(s0)
    8000589c:	fe843503          	ld	a0,-24(s0)
    800058a0:	fffff097          	auipc	ra,0xfffff
    800058a4:	43e080e7          	jalr	1086(ra) # 80004cde <fileread>
}
    800058a8:	70a2                	ld	ra,40(sp)
    800058aa:	7402                	ld	s0,32(sp)
    800058ac:	6145                	addi	sp,sp,48
    800058ae:	8082                	ret

00000000800058b0 <sys_write>:
{
    800058b0:	7179                	addi	sp,sp,-48
    800058b2:	f406                	sd	ra,40(sp)
    800058b4:	f022                	sd	s0,32(sp)
    800058b6:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800058b8:	fd840593          	addi	a1,s0,-40
    800058bc:	4505                	li	a0,1
    800058be:	ffffd097          	auipc	ra,0xffffd
    800058c2:	7ec080e7          	jalr	2028(ra) # 800030aa <argaddr>
  argint(2, &n);
    800058c6:	fe440593          	addi	a1,s0,-28
    800058ca:	4509                	li	a0,2
    800058cc:	ffffd097          	auipc	ra,0xffffd
    800058d0:	7be080e7          	jalr	1982(ra) # 8000308a <argint>
  if(argfd(0, 0, &f) < 0)
    800058d4:	fe840613          	addi	a2,s0,-24
    800058d8:	4581                	li	a1,0
    800058da:	4501                	li	a0,0
    800058dc:	00000097          	auipc	ra,0x0
    800058e0:	d02080e7          	jalr	-766(ra) # 800055de <argfd>
    800058e4:	87aa                	mv	a5,a0
    return -1;
    800058e6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058e8:	0007cc63          	bltz	a5,80005900 <sys_write+0x50>
  return filewrite(f, p, n);
    800058ec:	fe442603          	lw	a2,-28(s0)
    800058f0:	fd843583          	ld	a1,-40(s0)
    800058f4:	fe843503          	ld	a0,-24(s0)
    800058f8:	fffff097          	auipc	ra,0xfffff
    800058fc:	4a8080e7          	jalr	1192(ra) # 80004da0 <filewrite>
}
    80005900:	70a2                	ld	ra,40(sp)
    80005902:	7402                	ld	s0,32(sp)
    80005904:	6145                	addi	sp,sp,48
    80005906:	8082                	ret

0000000080005908 <sys_close>:
{
    80005908:	1101                	addi	sp,sp,-32
    8000590a:	ec06                	sd	ra,24(sp)
    8000590c:	e822                	sd	s0,16(sp)
    8000590e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005910:	fe040613          	addi	a2,s0,-32
    80005914:	fec40593          	addi	a1,s0,-20
    80005918:	4501                	li	a0,0
    8000591a:	00000097          	auipc	ra,0x0
    8000591e:	cc4080e7          	jalr	-828(ra) # 800055de <argfd>
    return -1;
    80005922:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005924:	02054463          	bltz	a0,8000594c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005928:	ffffc097          	auipc	ra,0xffffc
    8000592c:	08c080e7          	jalr	140(ra) # 800019b4 <myproc>
    80005930:	fec42783          	lw	a5,-20(s0)
    80005934:	07e9                	addi	a5,a5,26
    80005936:	078e                	slli	a5,a5,0x3
    80005938:	97aa                	add	a5,a5,a0
    8000593a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000593e:	fe043503          	ld	a0,-32(s0)
    80005942:	fffff097          	auipc	ra,0xfffff
    80005946:	262080e7          	jalr	610(ra) # 80004ba4 <fileclose>
  return 0;
    8000594a:	4781                	li	a5,0
}
    8000594c:	853e                	mv	a0,a5
    8000594e:	60e2                	ld	ra,24(sp)
    80005950:	6442                	ld	s0,16(sp)
    80005952:	6105                	addi	sp,sp,32
    80005954:	8082                	ret

0000000080005956 <sys_fstat>:
{
    80005956:	1101                	addi	sp,sp,-32
    80005958:	ec06                	sd	ra,24(sp)
    8000595a:	e822                	sd	s0,16(sp)
    8000595c:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000595e:	fe040593          	addi	a1,s0,-32
    80005962:	4505                	li	a0,1
    80005964:	ffffd097          	auipc	ra,0xffffd
    80005968:	746080e7          	jalr	1862(ra) # 800030aa <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000596c:	fe840613          	addi	a2,s0,-24
    80005970:	4581                	li	a1,0
    80005972:	4501                	li	a0,0
    80005974:	00000097          	auipc	ra,0x0
    80005978:	c6a080e7          	jalr	-918(ra) # 800055de <argfd>
    8000597c:	87aa                	mv	a5,a0
    return -1;
    8000597e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005980:	0007ca63          	bltz	a5,80005994 <sys_fstat+0x3e>
  return filestat(f, st);
    80005984:	fe043583          	ld	a1,-32(s0)
    80005988:	fe843503          	ld	a0,-24(s0)
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	2e0080e7          	jalr	736(ra) # 80004c6c <filestat>
}
    80005994:	60e2                	ld	ra,24(sp)
    80005996:	6442                	ld	s0,16(sp)
    80005998:	6105                	addi	sp,sp,32
    8000599a:	8082                	ret

000000008000599c <sys_link>:
{
    8000599c:	7169                	addi	sp,sp,-304
    8000599e:	f606                	sd	ra,296(sp)
    800059a0:	f222                	sd	s0,288(sp)
    800059a2:	ee26                	sd	s1,280(sp)
    800059a4:	ea4a                	sd	s2,272(sp)
    800059a6:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059a8:	08000613          	li	a2,128
    800059ac:	ed040593          	addi	a1,s0,-304
    800059b0:	4501                	li	a0,0
    800059b2:	ffffd097          	auipc	ra,0xffffd
    800059b6:	718080e7          	jalr	1816(ra) # 800030ca <argstr>
    return -1;
    800059ba:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059bc:	10054e63          	bltz	a0,80005ad8 <sys_link+0x13c>
    800059c0:	08000613          	li	a2,128
    800059c4:	f5040593          	addi	a1,s0,-176
    800059c8:	4505                	li	a0,1
    800059ca:	ffffd097          	auipc	ra,0xffffd
    800059ce:	700080e7          	jalr	1792(ra) # 800030ca <argstr>
    return -1;
    800059d2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059d4:	10054263          	bltz	a0,80005ad8 <sys_link+0x13c>
  begin_op();
    800059d8:	fffff097          	auipc	ra,0xfffff
    800059dc:	d00080e7          	jalr	-768(ra) # 800046d8 <begin_op>
  if((ip = namei(old)) == 0){
    800059e0:	ed040513          	addi	a0,s0,-304
    800059e4:	fffff097          	auipc	ra,0xfffff
    800059e8:	ad8080e7          	jalr	-1320(ra) # 800044bc <namei>
    800059ec:	84aa                	mv	s1,a0
    800059ee:	c551                	beqz	a0,80005a7a <sys_link+0xde>
  ilock(ip);
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	326080e7          	jalr	806(ra) # 80003d16 <ilock>
  if(ip->type == T_DIR){
    800059f8:	04449703          	lh	a4,68(s1)
    800059fc:	4785                	li	a5,1
    800059fe:	08f70463          	beq	a4,a5,80005a86 <sys_link+0xea>
  ip->nlink++;
    80005a02:	04a4d783          	lhu	a5,74(s1)
    80005a06:	2785                	addiw	a5,a5,1
    80005a08:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a0c:	8526                	mv	a0,s1
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	23e080e7          	jalr	574(ra) # 80003c4c <iupdate>
  iunlock(ip);
    80005a16:	8526                	mv	a0,s1
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	3c0080e7          	jalr	960(ra) # 80003dd8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005a20:	fd040593          	addi	a1,s0,-48
    80005a24:	f5040513          	addi	a0,s0,-176
    80005a28:	fffff097          	auipc	ra,0xfffff
    80005a2c:	ab2080e7          	jalr	-1358(ra) # 800044da <nameiparent>
    80005a30:	892a                	mv	s2,a0
    80005a32:	c935                	beqz	a0,80005aa6 <sys_link+0x10a>
  ilock(dp);
    80005a34:	ffffe097          	auipc	ra,0xffffe
    80005a38:	2e2080e7          	jalr	738(ra) # 80003d16 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a3c:	00092703          	lw	a4,0(s2)
    80005a40:	409c                	lw	a5,0(s1)
    80005a42:	04f71d63          	bne	a4,a5,80005a9c <sys_link+0x100>
    80005a46:	40d0                	lw	a2,4(s1)
    80005a48:	fd040593          	addi	a1,s0,-48
    80005a4c:	854a                	mv	a0,s2
    80005a4e:	fffff097          	auipc	ra,0xfffff
    80005a52:	9bc080e7          	jalr	-1604(ra) # 8000440a <dirlink>
    80005a56:	04054363          	bltz	a0,80005a9c <sys_link+0x100>
  iunlockput(dp);
    80005a5a:	854a                	mv	a0,s2
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	51c080e7          	jalr	1308(ra) # 80003f78 <iunlockput>
  iput(ip);
    80005a64:	8526                	mv	a0,s1
    80005a66:	ffffe097          	auipc	ra,0xffffe
    80005a6a:	46a080e7          	jalr	1130(ra) # 80003ed0 <iput>
  end_op();
    80005a6e:	fffff097          	auipc	ra,0xfffff
    80005a72:	cea080e7          	jalr	-790(ra) # 80004758 <end_op>
  return 0;
    80005a76:	4781                	li	a5,0
    80005a78:	a085                	j	80005ad8 <sys_link+0x13c>
    end_op();
    80005a7a:	fffff097          	auipc	ra,0xfffff
    80005a7e:	cde080e7          	jalr	-802(ra) # 80004758 <end_op>
    return -1;
    80005a82:	57fd                	li	a5,-1
    80005a84:	a891                	j	80005ad8 <sys_link+0x13c>
    iunlockput(ip);
    80005a86:	8526                	mv	a0,s1
    80005a88:	ffffe097          	auipc	ra,0xffffe
    80005a8c:	4f0080e7          	jalr	1264(ra) # 80003f78 <iunlockput>
    end_op();
    80005a90:	fffff097          	auipc	ra,0xfffff
    80005a94:	cc8080e7          	jalr	-824(ra) # 80004758 <end_op>
    return -1;
    80005a98:	57fd                	li	a5,-1
    80005a9a:	a83d                	j	80005ad8 <sys_link+0x13c>
    iunlockput(dp);
    80005a9c:	854a                	mv	a0,s2
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	4da080e7          	jalr	1242(ra) # 80003f78 <iunlockput>
  ilock(ip);
    80005aa6:	8526                	mv	a0,s1
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	26e080e7          	jalr	622(ra) # 80003d16 <ilock>
  ip->nlink--;
    80005ab0:	04a4d783          	lhu	a5,74(s1)
    80005ab4:	37fd                	addiw	a5,a5,-1
    80005ab6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005aba:	8526                	mv	a0,s1
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	190080e7          	jalr	400(ra) # 80003c4c <iupdate>
  iunlockput(ip);
    80005ac4:	8526                	mv	a0,s1
    80005ac6:	ffffe097          	auipc	ra,0xffffe
    80005aca:	4b2080e7          	jalr	1202(ra) # 80003f78 <iunlockput>
  end_op();
    80005ace:	fffff097          	auipc	ra,0xfffff
    80005ad2:	c8a080e7          	jalr	-886(ra) # 80004758 <end_op>
  return -1;
    80005ad6:	57fd                	li	a5,-1
}
    80005ad8:	853e                	mv	a0,a5
    80005ada:	70b2                	ld	ra,296(sp)
    80005adc:	7412                	ld	s0,288(sp)
    80005ade:	64f2                	ld	s1,280(sp)
    80005ae0:	6952                	ld	s2,272(sp)
    80005ae2:	6155                	addi	sp,sp,304
    80005ae4:	8082                	ret

0000000080005ae6 <sys_unlink>:
{
    80005ae6:	7151                	addi	sp,sp,-240
    80005ae8:	f586                	sd	ra,232(sp)
    80005aea:	f1a2                	sd	s0,224(sp)
    80005aec:	eda6                	sd	s1,216(sp)
    80005aee:	e9ca                	sd	s2,208(sp)
    80005af0:	e5ce                	sd	s3,200(sp)
    80005af2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005af4:	08000613          	li	a2,128
    80005af8:	f3040593          	addi	a1,s0,-208
    80005afc:	4501                	li	a0,0
    80005afe:	ffffd097          	auipc	ra,0xffffd
    80005b02:	5cc080e7          	jalr	1484(ra) # 800030ca <argstr>
    80005b06:	18054163          	bltz	a0,80005c88 <sys_unlink+0x1a2>
  begin_op();
    80005b0a:	fffff097          	auipc	ra,0xfffff
    80005b0e:	bce080e7          	jalr	-1074(ra) # 800046d8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005b12:	fb040593          	addi	a1,s0,-80
    80005b16:	f3040513          	addi	a0,s0,-208
    80005b1a:	fffff097          	auipc	ra,0xfffff
    80005b1e:	9c0080e7          	jalr	-1600(ra) # 800044da <nameiparent>
    80005b22:	84aa                	mv	s1,a0
    80005b24:	c979                	beqz	a0,80005bfa <sys_unlink+0x114>
  ilock(dp);
    80005b26:	ffffe097          	auipc	ra,0xffffe
    80005b2a:	1f0080e7          	jalr	496(ra) # 80003d16 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b2e:	00003597          	auipc	a1,0x3
    80005b32:	bea58593          	addi	a1,a1,-1046 # 80008718 <syscalls+0x2c8>
    80005b36:	fb040513          	addi	a0,s0,-80
    80005b3a:	ffffe097          	auipc	ra,0xffffe
    80005b3e:	6a6080e7          	jalr	1702(ra) # 800041e0 <namecmp>
    80005b42:	14050a63          	beqz	a0,80005c96 <sys_unlink+0x1b0>
    80005b46:	00003597          	auipc	a1,0x3
    80005b4a:	bda58593          	addi	a1,a1,-1062 # 80008720 <syscalls+0x2d0>
    80005b4e:	fb040513          	addi	a0,s0,-80
    80005b52:	ffffe097          	auipc	ra,0xffffe
    80005b56:	68e080e7          	jalr	1678(ra) # 800041e0 <namecmp>
    80005b5a:	12050e63          	beqz	a0,80005c96 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b5e:	f2c40613          	addi	a2,s0,-212
    80005b62:	fb040593          	addi	a1,s0,-80
    80005b66:	8526                	mv	a0,s1
    80005b68:	ffffe097          	auipc	ra,0xffffe
    80005b6c:	692080e7          	jalr	1682(ra) # 800041fa <dirlookup>
    80005b70:	892a                	mv	s2,a0
    80005b72:	12050263          	beqz	a0,80005c96 <sys_unlink+0x1b0>
  ilock(ip);
    80005b76:	ffffe097          	auipc	ra,0xffffe
    80005b7a:	1a0080e7          	jalr	416(ra) # 80003d16 <ilock>
  if(ip->nlink < 1)
    80005b7e:	04a91783          	lh	a5,74(s2)
    80005b82:	08f05263          	blez	a5,80005c06 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b86:	04491703          	lh	a4,68(s2)
    80005b8a:	4785                	li	a5,1
    80005b8c:	08f70563          	beq	a4,a5,80005c16 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b90:	4641                	li	a2,16
    80005b92:	4581                	li	a1,0
    80005b94:	fc040513          	addi	a0,s0,-64
    80005b98:	ffffb097          	auipc	ra,0xffffb
    80005b9c:	13a080e7          	jalr	314(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ba0:	4741                	li	a4,16
    80005ba2:	f2c42683          	lw	a3,-212(s0)
    80005ba6:	fc040613          	addi	a2,s0,-64
    80005baa:	4581                	li	a1,0
    80005bac:	8526                	mv	a0,s1
    80005bae:	ffffe097          	auipc	ra,0xffffe
    80005bb2:	514080e7          	jalr	1300(ra) # 800040c2 <writei>
    80005bb6:	47c1                	li	a5,16
    80005bb8:	0af51563          	bne	a0,a5,80005c62 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005bbc:	04491703          	lh	a4,68(s2)
    80005bc0:	4785                	li	a5,1
    80005bc2:	0af70863          	beq	a4,a5,80005c72 <sys_unlink+0x18c>
  iunlockput(dp);
    80005bc6:	8526                	mv	a0,s1
    80005bc8:	ffffe097          	auipc	ra,0xffffe
    80005bcc:	3b0080e7          	jalr	944(ra) # 80003f78 <iunlockput>
  ip->nlink--;
    80005bd0:	04a95783          	lhu	a5,74(s2)
    80005bd4:	37fd                	addiw	a5,a5,-1
    80005bd6:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005bda:	854a                	mv	a0,s2
    80005bdc:	ffffe097          	auipc	ra,0xffffe
    80005be0:	070080e7          	jalr	112(ra) # 80003c4c <iupdate>
  iunlockput(ip);
    80005be4:	854a                	mv	a0,s2
    80005be6:	ffffe097          	auipc	ra,0xffffe
    80005bea:	392080e7          	jalr	914(ra) # 80003f78 <iunlockput>
  end_op();
    80005bee:	fffff097          	auipc	ra,0xfffff
    80005bf2:	b6a080e7          	jalr	-1174(ra) # 80004758 <end_op>
  return 0;
    80005bf6:	4501                	li	a0,0
    80005bf8:	a84d                	j	80005caa <sys_unlink+0x1c4>
    end_op();
    80005bfa:	fffff097          	auipc	ra,0xfffff
    80005bfe:	b5e080e7          	jalr	-1186(ra) # 80004758 <end_op>
    return -1;
    80005c02:	557d                	li	a0,-1
    80005c04:	a05d                	j	80005caa <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005c06:	00003517          	auipc	a0,0x3
    80005c0a:	b2250513          	addi	a0,a0,-1246 # 80008728 <syscalls+0x2d8>
    80005c0e:	ffffb097          	auipc	ra,0xffffb
    80005c12:	930080e7          	jalr	-1744(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c16:	04c92703          	lw	a4,76(s2)
    80005c1a:	02000793          	li	a5,32
    80005c1e:	f6e7f9e3          	bgeu	a5,a4,80005b90 <sys_unlink+0xaa>
    80005c22:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c26:	4741                	li	a4,16
    80005c28:	86ce                	mv	a3,s3
    80005c2a:	f1840613          	addi	a2,s0,-232
    80005c2e:	4581                	li	a1,0
    80005c30:	854a                	mv	a0,s2
    80005c32:	ffffe097          	auipc	ra,0xffffe
    80005c36:	398080e7          	jalr	920(ra) # 80003fca <readi>
    80005c3a:	47c1                	li	a5,16
    80005c3c:	00f51b63          	bne	a0,a5,80005c52 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c40:	f1845783          	lhu	a5,-232(s0)
    80005c44:	e7a1                	bnez	a5,80005c8c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c46:	29c1                	addiw	s3,s3,16
    80005c48:	04c92783          	lw	a5,76(s2)
    80005c4c:	fcf9ede3          	bltu	s3,a5,80005c26 <sys_unlink+0x140>
    80005c50:	b781                	j	80005b90 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c52:	00003517          	auipc	a0,0x3
    80005c56:	aee50513          	addi	a0,a0,-1298 # 80008740 <syscalls+0x2f0>
    80005c5a:	ffffb097          	auipc	ra,0xffffb
    80005c5e:	8e4080e7          	jalr	-1820(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005c62:	00003517          	auipc	a0,0x3
    80005c66:	af650513          	addi	a0,a0,-1290 # 80008758 <syscalls+0x308>
    80005c6a:	ffffb097          	auipc	ra,0xffffb
    80005c6e:	8d4080e7          	jalr	-1836(ra) # 8000053e <panic>
    dp->nlink--;
    80005c72:	04a4d783          	lhu	a5,74(s1)
    80005c76:	37fd                	addiw	a5,a5,-1
    80005c78:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c7c:	8526                	mv	a0,s1
    80005c7e:	ffffe097          	auipc	ra,0xffffe
    80005c82:	fce080e7          	jalr	-50(ra) # 80003c4c <iupdate>
    80005c86:	b781                	j	80005bc6 <sys_unlink+0xe0>
    return -1;
    80005c88:	557d                	li	a0,-1
    80005c8a:	a005                	j	80005caa <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c8c:	854a                	mv	a0,s2
    80005c8e:	ffffe097          	auipc	ra,0xffffe
    80005c92:	2ea080e7          	jalr	746(ra) # 80003f78 <iunlockput>
  iunlockput(dp);
    80005c96:	8526                	mv	a0,s1
    80005c98:	ffffe097          	auipc	ra,0xffffe
    80005c9c:	2e0080e7          	jalr	736(ra) # 80003f78 <iunlockput>
  end_op();
    80005ca0:	fffff097          	auipc	ra,0xfffff
    80005ca4:	ab8080e7          	jalr	-1352(ra) # 80004758 <end_op>
  return -1;
    80005ca8:	557d                	li	a0,-1
}
    80005caa:	70ae                	ld	ra,232(sp)
    80005cac:	740e                	ld	s0,224(sp)
    80005cae:	64ee                	ld	s1,216(sp)
    80005cb0:	694e                	ld	s2,208(sp)
    80005cb2:	69ae                	ld	s3,200(sp)
    80005cb4:	616d                	addi	sp,sp,240
    80005cb6:	8082                	ret

0000000080005cb8 <sys_open>:

uint64
sys_open(void)
{
    80005cb8:	7131                	addi	sp,sp,-192
    80005cba:	fd06                	sd	ra,184(sp)
    80005cbc:	f922                	sd	s0,176(sp)
    80005cbe:	f526                	sd	s1,168(sp)
    80005cc0:	f14a                	sd	s2,160(sp)
    80005cc2:	ed4e                	sd	s3,152(sp)
    80005cc4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005cc6:	f4c40593          	addi	a1,s0,-180
    80005cca:	4505                	li	a0,1
    80005ccc:	ffffd097          	auipc	ra,0xffffd
    80005cd0:	3be080e7          	jalr	958(ra) # 8000308a <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005cd4:	08000613          	li	a2,128
    80005cd8:	f5040593          	addi	a1,s0,-176
    80005cdc:	4501                	li	a0,0
    80005cde:	ffffd097          	auipc	ra,0xffffd
    80005ce2:	3ec080e7          	jalr	1004(ra) # 800030ca <argstr>
    80005ce6:	87aa                	mv	a5,a0
    return -1;
    80005ce8:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005cea:	0a07c963          	bltz	a5,80005d9c <sys_open+0xe4>

  begin_op();
    80005cee:	fffff097          	auipc	ra,0xfffff
    80005cf2:	9ea080e7          	jalr	-1558(ra) # 800046d8 <begin_op>

  if(omode & O_CREATE){
    80005cf6:	f4c42783          	lw	a5,-180(s0)
    80005cfa:	2007f793          	andi	a5,a5,512
    80005cfe:	cfc5                	beqz	a5,80005db6 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005d00:	4681                	li	a3,0
    80005d02:	4601                	li	a2,0
    80005d04:	4589                	li	a1,2
    80005d06:	f5040513          	addi	a0,s0,-176
    80005d0a:	00000097          	auipc	ra,0x0
    80005d0e:	976080e7          	jalr	-1674(ra) # 80005680 <create>
    80005d12:	84aa                	mv	s1,a0
    if(ip == 0){
    80005d14:	c959                	beqz	a0,80005daa <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005d16:	04449703          	lh	a4,68(s1)
    80005d1a:	478d                	li	a5,3
    80005d1c:	00f71763          	bne	a4,a5,80005d2a <sys_open+0x72>
    80005d20:	0464d703          	lhu	a4,70(s1)
    80005d24:	47a5                	li	a5,9
    80005d26:	0ce7ed63          	bltu	a5,a4,80005e00 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d2a:	fffff097          	auipc	ra,0xfffff
    80005d2e:	dbe080e7          	jalr	-578(ra) # 80004ae8 <filealloc>
    80005d32:	89aa                	mv	s3,a0
    80005d34:	10050363          	beqz	a0,80005e3a <sys_open+0x182>
    80005d38:	00000097          	auipc	ra,0x0
    80005d3c:	906080e7          	jalr	-1786(ra) # 8000563e <fdalloc>
    80005d40:	892a                	mv	s2,a0
    80005d42:	0e054763          	bltz	a0,80005e30 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d46:	04449703          	lh	a4,68(s1)
    80005d4a:	478d                	li	a5,3
    80005d4c:	0cf70563          	beq	a4,a5,80005e16 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d50:	4789                	li	a5,2
    80005d52:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005d56:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005d5a:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005d5e:	f4c42783          	lw	a5,-180(s0)
    80005d62:	0017c713          	xori	a4,a5,1
    80005d66:	8b05                	andi	a4,a4,1
    80005d68:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d6c:	0037f713          	andi	a4,a5,3
    80005d70:	00e03733          	snez	a4,a4
    80005d74:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d78:	4007f793          	andi	a5,a5,1024
    80005d7c:	c791                	beqz	a5,80005d88 <sys_open+0xd0>
    80005d7e:	04449703          	lh	a4,68(s1)
    80005d82:	4789                	li	a5,2
    80005d84:	0af70063          	beq	a4,a5,80005e24 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d88:	8526                	mv	a0,s1
    80005d8a:	ffffe097          	auipc	ra,0xffffe
    80005d8e:	04e080e7          	jalr	78(ra) # 80003dd8 <iunlock>
  end_op();
    80005d92:	fffff097          	auipc	ra,0xfffff
    80005d96:	9c6080e7          	jalr	-1594(ra) # 80004758 <end_op>

  return fd;
    80005d9a:	854a                	mv	a0,s2
}
    80005d9c:	70ea                	ld	ra,184(sp)
    80005d9e:	744a                	ld	s0,176(sp)
    80005da0:	74aa                	ld	s1,168(sp)
    80005da2:	790a                	ld	s2,160(sp)
    80005da4:	69ea                	ld	s3,152(sp)
    80005da6:	6129                	addi	sp,sp,192
    80005da8:	8082                	ret
      end_op();
    80005daa:	fffff097          	auipc	ra,0xfffff
    80005dae:	9ae080e7          	jalr	-1618(ra) # 80004758 <end_op>
      return -1;
    80005db2:	557d                	li	a0,-1
    80005db4:	b7e5                	j	80005d9c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005db6:	f5040513          	addi	a0,s0,-176
    80005dba:	ffffe097          	auipc	ra,0xffffe
    80005dbe:	702080e7          	jalr	1794(ra) # 800044bc <namei>
    80005dc2:	84aa                	mv	s1,a0
    80005dc4:	c905                	beqz	a0,80005df4 <sys_open+0x13c>
    ilock(ip);
    80005dc6:	ffffe097          	auipc	ra,0xffffe
    80005dca:	f50080e7          	jalr	-176(ra) # 80003d16 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005dce:	04449703          	lh	a4,68(s1)
    80005dd2:	4785                	li	a5,1
    80005dd4:	f4f711e3          	bne	a4,a5,80005d16 <sys_open+0x5e>
    80005dd8:	f4c42783          	lw	a5,-180(s0)
    80005ddc:	d7b9                	beqz	a5,80005d2a <sys_open+0x72>
      iunlockput(ip);
    80005dde:	8526                	mv	a0,s1
    80005de0:	ffffe097          	auipc	ra,0xffffe
    80005de4:	198080e7          	jalr	408(ra) # 80003f78 <iunlockput>
      end_op();
    80005de8:	fffff097          	auipc	ra,0xfffff
    80005dec:	970080e7          	jalr	-1680(ra) # 80004758 <end_op>
      return -1;
    80005df0:	557d                	li	a0,-1
    80005df2:	b76d                	j	80005d9c <sys_open+0xe4>
      end_op();
    80005df4:	fffff097          	auipc	ra,0xfffff
    80005df8:	964080e7          	jalr	-1692(ra) # 80004758 <end_op>
      return -1;
    80005dfc:	557d                	li	a0,-1
    80005dfe:	bf79                	j	80005d9c <sys_open+0xe4>
    iunlockput(ip);
    80005e00:	8526                	mv	a0,s1
    80005e02:	ffffe097          	auipc	ra,0xffffe
    80005e06:	176080e7          	jalr	374(ra) # 80003f78 <iunlockput>
    end_op();
    80005e0a:	fffff097          	auipc	ra,0xfffff
    80005e0e:	94e080e7          	jalr	-1714(ra) # 80004758 <end_op>
    return -1;
    80005e12:	557d                	li	a0,-1
    80005e14:	b761                	j	80005d9c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005e16:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005e1a:	04649783          	lh	a5,70(s1)
    80005e1e:	02f99223          	sh	a5,36(s3)
    80005e22:	bf25                	j	80005d5a <sys_open+0xa2>
    itrunc(ip);
    80005e24:	8526                	mv	a0,s1
    80005e26:	ffffe097          	auipc	ra,0xffffe
    80005e2a:	ffe080e7          	jalr	-2(ra) # 80003e24 <itrunc>
    80005e2e:	bfa9                	j	80005d88 <sys_open+0xd0>
      fileclose(f);
    80005e30:	854e                	mv	a0,s3
    80005e32:	fffff097          	auipc	ra,0xfffff
    80005e36:	d72080e7          	jalr	-654(ra) # 80004ba4 <fileclose>
    iunlockput(ip);
    80005e3a:	8526                	mv	a0,s1
    80005e3c:	ffffe097          	auipc	ra,0xffffe
    80005e40:	13c080e7          	jalr	316(ra) # 80003f78 <iunlockput>
    end_op();
    80005e44:	fffff097          	auipc	ra,0xfffff
    80005e48:	914080e7          	jalr	-1772(ra) # 80004758 <end_op>
    return -1;
    80005e4c:	557d                	li	a0,-1
    80005e4e:	b7b9                	j	80005d9c <sys_open+0xe4>

0000000080005e50 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e50:	7175                	addi	sp,sp,-144
    80005e52:	e506                	sd	ra,136(sp)
    80005e54:	e122                	sd	s0,128(sp)
    80005e56:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e58:	fffff097          	auipc	ra,0xfffff
    80005e5c:	880080e7          	jalr	-1920(ra) # 800046d8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e60:	08000613          	li	a2,128
    80005e64:	f7040593          	addi	a1,s0,-144
    80005e68:	4501                	li	a0,0
    80005e6a:	ffffd097          	auipc	ra,0xffffd
    80005e6e:	260080e7          	jalr	608(ra) # 800030ca <argstr>
    80005e72:	02054963          	bltz	a0,80005ea4 <sys_mkdir+0x54>
    80005e76:	4681                	li	a3,0
    80005e78:	4601                	li	a2,0
    80005e7a:	4585                	li	a1,1
    80005e7c:	f7040513          	addi	a0,s0,-144
    80005e80:	00000097          	auipc	ra,0x0
    80005e84:	800080e7          	jalr	-2048(ra) # 80005680 <create>
    80005e88:	cd11                	beqz	a0,80005ea4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e8a:	ffffe097          	auipc	ra,0xffffe
    80005e8e:	0ee080e7          	jalr	238(ra) # 80003f78 <iunlockput>
  end_op();
    80005e92:	fffff097          	auipc	ra,0xfffff
    80005e96:	8c6080e7          	jalr	-1850(ra) # 80004758 <end_op>
  return 0;
    80005e9a:	4501                	li	a0,0
}
    80005e9c:	60aa                	ld	ra,136(sp)
    80005e9e:	640a                	ld	s0,128(sp)
    80005ea0:	6149                	addi	sp,sp,144
    80005ea2:	8082                	ret
    end_op();
    80005ea4:	fffff097          	auipc	ra,0xfffff
    80005ea8:	8b4080e7          	jalr	-1868(ra) # 80004758 <end_op>
    return -1;
    80005eac:	557d                	li	a0,-1
    80005eae:	b7fd                	j	80005e9c <sys_mkdir+0x4c>

0000000080005eb0 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005eb0:	7135                	addi	sp,sp,-160
    80005eb2:	ed06                	sd	ra,152(sp)
    80005eb4:	e922                	sd	s0,144(sp)
    80005eb6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005eb8:	fffff097          	auipc	ra,0xfffff
    80005ebc:	820080e7          	jalr	-2016(ra) # 800046d8 <begin_op>
  argint(1, &major);
    80005ec0:	f6c40593          	addi	a1,s0,-148
    80005ec4:	4505                	li	a0,1
    80005ec6:	ffffd097          	auipc	ra,0xffffd
    80005eca:	1c4080e7          	jalr	452(ra) # 8000308a <argint>
  argint(2, &minor);
    80005ece:	f6840593          	addi	a1,s0,-152
    80005ed2:	4509                	li	a0,2
    80005ed4:	ffffd097          	auipc	ra,0xffffd
    80005ed8:	1b6080e7          	jalr	438(ra) # 8000308a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005edc:	08000613          	li	a2,128
    80005ee0:	f7040593          	addi	a1,s0,-144
    80005ee4:	4501                	li	a0,0
    80005ee6:	ffffd097          	auipc	ra,0xffffd
    80005eea:	1e4080e7          	jalr	484(ra) # 800030ca <argstr>
    80005eee:	02054b63          	bltz	a0,80005f24 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ef2:	f6841683          	lh	a3,-152(s0)
    80005ef6:	f6c41603          	lh	a2,-148(s0)
    80005efa:	458d                	li	a1,3
    80005efc:	f7040513          	addi	a0,s0,-144
    80005f00:	fffff097          	auipc	ra,0xfffff
    80005f04:	780080e7          	jalr	1920(ra) # 80005680 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f08:	cd11                	beqz	a0,80005f24 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f0a:	ffffe097          	auipc	ra,0xffffe
    80005f0e:	06e080e7          	jalr	110(ra) # 80003f78 <iunlockput>
  end_op();
    80005f12:	fffff097          	auipc	ra,0xfffff
    80005f16:	846080e7          	jalr	-1978(ra) # 80004758 <end_op>
  return 0;
    80005f1a:	4501                	li	a0,0
}
    80005f1c:	60ea                	ld	ra,152(sp)
    80005f1e:	644a                	ld	s0,144(sp)
    80005f20:	610d                	addi	sp,sp,160
    80005f22:	8082                	ret
    end_op();
    80005f24:	fffff097          	auipc	ra,0xfffff
    80005f28:	834080e7          	jalr	-1996(ra) # 80004758 <end_op>
    return -1;
    80005f2c:	557d                	li	a0,-1
    80005f2e:	b7fd                	j	80005f1c <sys_mknod+0x6c>

0000000080005f30 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f30:	7135                	addi	sp,sp,-160
    80005f32:	ed06                	sd	ra,152(sp)
    80005f34:	e922                	sd	s0,144(sp)
    80005f36:	e526                	sd	s1,136(sp)
    80005f38:	e14a                	sd	s2,128(sp)
    80005f3a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f3c:	ffffc097          	auipc	ra,0xffffc
    80005f40:	a78080e7          	jalr	-1416(ra) # 800019b4 <myproc>
    80005f44:	892a                	mv	s2,a0
  
  begin_op();
    80005f46:	ffffe097          	auipc	ra,0xffffe
    80005f4a:	792080e7          	jalr	1938(ra) # 800046d8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f4e:	08000613          	li	a2,128
    80005f52:	f6040593          	addi	a1,s0,-160
    80005f56:	4501                	li	a0,0
    80005f58:	ffffd097          	auipc	ra,0xffffd
    80005f5c:	172080e7          	jalr	370(ra) # 800030ca <argstr>
    80005f60:	04054b63          	bltz	a0,80005fb6 <sys_chdir+0x86>
    80005f64:	f6040513          	addi	a0,s0,-160
    80005f68:	ffffe097          	auipc	ra,0xffffe
    80005f6c:	554080e7          	jalr	1364(ra) # 800044bc <namei>
    80005f70:	84aa                	mv	s1,a0
    80005f72:	c131                	beqz	a0,80005fb6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f74:	ffffe097          	auipc	ra,0xffffe
    80005f78:	da2080e7          	jalr	-606(ra) # 80003d16 <ilock>
  if(ip->type != T_DIR){
    80005f7c:	04449703          	lh	a4,68(s1)
    80005f80:	4785                	li	a5,1
    80005f82:	04f71063          	bne	a4,a5,80005fc2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f86:	8526                	mv	a0,s1
    80005f88:	ffffe097          	auipc	ra,0xffffe
    80005f8c:	e50080e7          	jalr	-432(ra) # 80003dd8 <iunlock>
  iput(p->cwd);
    80005f90:	15093503          	ld	a0,336(s2)
    80005f94:	ffffe097          	auipc	ra,0xffffe
    80005f98:	f3c080e7          	jalr	-196(ra) # 80003ed0 <iput>
  end_op();
    80005f9c:	ffffe097          	auipc	ra,0xffffe
    80005fa0:	7bc080e7          	jalr	1980(ra) # 80004758 <end_op>
  p->cwd = ip;
    80005fa4:	14993823          	sd	s1,336(s2)
  return 0;
    80005fa8:	4501                	li	a0,0
}
    80005faa:	60ea                	ld	ra,152(sp)
    80005fac:	644a                	ld	s0,144(sp)
    80005fae:	64aa                	ld	s1,136(sp)
    80005fb0:	690a                	ld	s2,128(sp)
    80005fb2:	610d                	addi	sp,sp,160
    80005fb4:	8082                	ret
    end_op();
    80005fb6:	ffffe097          	auipc	ra,0xffffe
    80005fba:	7a2080e7          	jalr	1954(ra) # 80004758 <end_op>
    return -1;
    80005fbe:	557d                	li	a0,-1
    80005fc0:	b7ed                	j	80005faa <sys_chdir+0x7a>
    iunlockput(ip);
    80005fc2:	8526                	mv	a0,s1
    80005fc4:	ffffe097          	auipc	ra,0xffffe
    80005fc8:	fb4080e7          	jalr	-76(ra) # 80003f78 <iunlockput>
    end_op();
    80005fcc:	ffffe097          	auipc	ra,0xffffe
    80005fd0:	78c080e7          	jalr	1932(ra) # 80004758 <end_op>
    return -1;
    80005fd4:	557d                	li	a0,-1
    80005fd6:	bfd1                	j	80005faa <sys_chdir+0x7a>

0000000080005fd8 <sys_exec>:

uint64
sys_exec(void)
{
    80005fd8:	7145                	addi	sp,sp,-464
    80005fda:	e786                	sd	ra,456(sp)
    80005fdc:	e3a2                	sd	s0,448(sp)
    80005fde:	ff26                	sd	s1,440(sp)
    80005fe0:	fb4a                	sd	s2,432(sp)
    80005fe2:	f74e                	sd	s3,424(sp)
    80005fe4:	f352                	sd	s4,416(sp)
    80005fe6:	ef56                	sd	s5,408(sp)
    80005fe8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005fea:	e3840593          	addi	a1,s0,-456
    80005fee:	4505                	li	a0,1
    80005ff0:	ffffd097          	auipc	ra,0xffffd
    80005ff4:	0ba080e7          	jalr	186(ra) # 800030aa <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005ff8:	08000613          	li	a2,128
    80005ffc:	f4040593          	addi	a1,s0,-192
    80006000:	4501                	li	a0,0
    80006002:	ffffd097          	auipc	ra,0xffffd
    80006006:	0c8080e7          	jalr	200(ra) # 800030ca <argstr>
    8000600a:	87aa                	mv	a5,a0
    return -1;
    8000600c:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000600e:	0c07c263          	bltz	a5,800060d2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006012:	10000613          	li	a2,256
    80006016:	4581                	li	a1,0
    80006018:	e4040513          	addi	a0,s0,-448
    8000601c:	ffffb097          	auipc	ra,0xffffb
    80006020:	cb6080e7          	jalr	-842(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006024:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006028:	89a6                	mv	s3,s1
    8000602a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000602c:	02000a13          	li	s4,32
    80006030:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006034:	00391793          	slli	a5,s2,0x3
    80006038:	e3040593          	addi	a1,s0,-464
    8000603c:	e3843503          	ld	a0,-456(s0)
    80006040:	953e                	add	a0,a0,a5
    80006042:	ffffd097          	auipc	ra,0xffffd
    80006046:	faa080e7          	jalr	-86(ra) # 80002fec <fetchaddr>
    8000604a:	02054a63          	bltz	a0,8000607e <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    8000604e:	e3043783          	ld	a5,-464(s0)
    80006052:	c3b9                	beqz	a5,80006098 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006054:	ffffb097          	auipc	ra,0xffffb
    80006058:	a92080e7          	jalr	-1390(ra) # 80000ae6 <kalloc>
    8000605c:	85aa                	mv	a1,a0
    8000605e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006062:	cd11                	beqz	a0,8000607e <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006064:	6605                	lui	a2,0x1
    80006066:	e3043503          	ld	a0,-464(s0)
    8000606a:	ffffd097          	auipc	ra,0xffffd
    8000606e:	fd4080e7          	jalr	-44(ra) # 8000303e <fetchstr>
    80006072:	00054663          	bltz	a0,8000607e <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006076:	0905                	addi	s2,s2,1
    80006078:	09a1                	addi	s3,s3,8
    8000607a:	fb491be3          	bne	s2,s4,80006030 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000607e:	10048913          	addi	s2,s1,256
    80006082:	6088                	ld	a0,0(s1)
    80006084:	c531                	beqz	a0,800060d0 <sys_exec+0xf8>
    kfree(argv[i]);
    80006086:	ffffb097          	auipc	ra,0xffffb
    8000608a:	964080e7          	jalr	-1692(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000608e:	04a1                	addi	s1,s1,8
    80006090:	ff2499e3          	bne	s1,s2,80006082 <sys_exec+0xaa>
  return -1;
    80006094:	557d                	li	a0,-1
    80006096:	a835                	j	800060d2 <sys_exec+0xfa>
      argv[i] = 0;
    80006098:	0a8e                	slli	s5,s5,0x3
    8000609a:	fc040793          	addi	a5,s0,-64
    8000609e:	9abe                	add	s5,s5,a5
    800060a0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800060a4:	e4040593          	addi	a1,s0,-448
    800060a8:	f4040513          	addi	a0,s0,-192
    800060ac:	fffff097          	auipc	ra,0xfffff
    800060b0:	172080e7          	jalr	370(ra) # 8000521e <exec>
    800060b4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060b6:	10048993          	addi	s3,s1,256
    800060ba:	6088                	ld	a0,0(s1)
    800060bc:	c901                	beqz	a0,800060cc <sys_exec+0xf4>
    kfree(argv[i]);
    800060be:	ffffb097          	auipc	ra,0xffffb
    800060c2:	92c080e7          	jalr	-1748(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060c6:	04a1                	addi	s1,s1,8
    800060c8:	ff3499e3          	bne	s1,s3,800060ba <sys_exec+0xe2>
  return ret;
    800060cc:	854a                	mv	a0,s2
    800060ce:	a011                	j	800060d2 <sys_exec+0xfa>
  return -1;
    800060d0:	557d                	li	a0,-1
}
    800060d2:	60be                	ld	ra,456(sp)
    800060d4:	641e                	ld	s0,448(sp)
    800060d6:	74fa                	ld	s1,440(sp)
    800060d8:	795a                	ld	s2,432(sp)
    800060da:	79ba                	ld	s3,424(sp)
    800060dc:	7a1a                	ld	s4,416(sp)
    800060de:	6afa                	ld	s5,408(sp)
    800060e0:	6179                	addi	sp,sp,464
    800060e2:	8082                	ret

00000000800060e4 <sys_pipe>:

uint64
sys_pipe(void)
{
    800060e4:	7139                	addi	sp,sp,-64
    800060e6:	fc06                	sd	ra,56(sp)
    800060e8:	f822                	sd	s0,48(sp)
    800060ea:	f426                	sd	s1,40(sp)
    800060ec:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800060ee:	ffffc097          	auipc	ra,0xffffc
    800060f2:	8c6080e7          	jalr	-1850(ra) # 800019b4 <myproc>
    800060f6:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800060f8:	fd840593          	addi	a1,s0,-40
    800060fc:	4501                	li	a0,0
    800060fe:	ffffd097          	auipc	ra,0xffffd
    80006102:	fac080e7          	jalr	-84(ra) # 800030aa <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006106:	fc840593          	addi	a1,s0,-56
    8000610a:	fd040513          	addi	a0,s0,-48
    8000610e:	fffff097          	auipc	ra,0xfffff
    80006112:	dc6080e7          	jalr	-570(ra) # 80004ed4 <pipealloc>
    return -1;
    80006116:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006118:	0c054463          	bltz	a0,800061e0 <sys_pipe+0xfc>
  fd0 = -1;
    8000611c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006120:	fd043503          	ld	a0,-48(s0)
    80006124:	fffff097          	auipc	ra,0xfffff
    80006128:	51a080e7          	jalr	1306(ra) # 8000563e <fdalloc>
    8000612c:	fca42223          	sw	a0,-60(s0)
    80006130:	08054b63          	bltz	a0,800061c6 <sys_pipe+0xe2>
    80006134:	fc843503          	ld	a0,-56(s0)
    80006138:	fffff097          	auipc	ra,0xfffff
    8000613c:	506080e7          	jalr	1286(ra) # 8000563e <fdalloc>
    80006140:	fca42023          	sw	a0,-64(s0)
    80006144:	06054863          	bltz	a0,800061b4 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006148:	4691                	li	a3,4
    8000614a:	fc440613          	addi	a2,s0,-60
    8000614e:	fd843583          	ld	a1,-40(s0)
    80006152:	68a8                	ld	a0,80(s1)
    80006154:	ffffb097          	auipc	ra,0xffffb
    80006158:	51c080e7          	jalr	1308(ra) # 80001670 <copyout>
    8000615c:	02054063          	bltz	a0,8000617c <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006160:	4691                	li	a3,4
    80006162:	fc040613          	addi	a2,s0,-64
    80006166:	fd843583          	ld	a1,-40(s0)
    8000616a:	0591                	addi	a1,a1,4
    8000616c:	68a8                	ld	a0,80(s1)
    8000616e:	ffffb097          	auipc	ra,0xffffb
    80006172:	502080e7          	jalr	1282(ra) # 80001670 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006176:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006178:	06055463          	bgez	a0,800061e0 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000617c:	fc442783          	lw	a5,-60(s0)
    80006180:	07e9                	addi	a5,a5,26
    80006182:	078e                	slli	a5,a5,0x3
    80006184:	97a6                	add	a5,a5,s1
    80006186:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000618a:	fc042503          	lw	a0,-64(s0)
    8000618e:	0569                	addi	a0,a0,26
    80006190:	050e                	slli	a0,a0,0x3
    80006192:	94aa                	add	s1,s1,a0
    80006194:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006198:	fd043503          	ld	a0,-48(s0)
    8000619c:	fffff097          	auipc	ra,0xfffff
    800061a0:	a08080e7          	jalr	-1528(ra) # 80004ba4 <fileclose>
    fileclose(wf);
    800061a4:	fc843503          	ld	a0,-56(s0)
    800061a8:	fffff097          	auipc	ra,0xfffff
    800061ac:	9fc080e7          	jalr	-1540(ra) # 80004ba4 <fileclose>
    return -1;
    800061b0:	57fd                	li	a5,-1
    800061b2:	a03d                	j	800061e0 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800061b4:	fc442783          	lw	a5,-60(s0)
    800061b8:	0007c763          	bltz	a5,800061c6 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800061bc:	07e9                	addi	a5,a5,26
    800061be:	078e                	slli	a5,a5,0x3
    800061c0:	94be                	add	s1,s1,a5
    800061c2:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800061c6:	fd043503          	ld	a0,-48(s0)
    800061ca:	fffff097          	auipc	ra,0xfffff
    800061ce:	9da080e7          	jalr	-1574(ra) # 80004ba4 <fileclose>
    fileclose(wf);
    800061d2:	fc843503          	ld	a0,-56(s0)
    800061d6:	fffff097          	auipc	ra,0xfffff
    800061da:	9ce080e7          	jalr	-1586(ra) # 80004ba4 <fileclose>
    return -1;
    800061de:	57fd                	li	a5,-1
}
    800061e0:	853e                	mv	a0,a5
    800061e2:	70e2                	ld	ra,56(sp)
    800061e4:	7442                	ld	s0,48(sp)
    800061e6:	74a2                	ld	s1,40(sp)
    800061e8:	6121                	addi	sp,sp,64
    800061ea:	8082                	ret
    800061ec:	0000                	unimp
	...

00000000800061f0 <kernelvec>:
    800061f0:	7111                	addi	sp,sp,-256
    800061f2:	e006                	sd	ra,0(sp)
    800061f4:	e40a                	sd	sp,8(sp)
    800061f6:	e80e                	sd	gp,16(sp)
    800061f8:	ec12                	sd	tp,24(sp)
    800061fa:	f016                	sd	t0,32(sp)
    800061fc:	f41a                	sd	t1,40(sp)
    800061fe:	f81e                	sd	t2,48(sp)
    80006200:	fc22                	sd	s0,56(sp)
    80006202:	e0a6                	sd	s1,64(sp)
    80006204:	e4aa                	sd	a0,72(sp)
    80006206:	e8ae                	sd	a1,80(sp)
    80006208:	ecb2                	sd	a2,88(sp)
    8000620a:	f0b6                	sd	a3,96(sp)
    8000620c:	f4ba                	sd	a4,104(sp)
    8000620e:	f8be                	sd	a5,112(sp)
    80006210:	fcc2                	sd	a6,120(sp)
    80006212:	e146                	sd	a7,128(sp)
    80006214:	e54a                	sd	s2,136(sp)
    80006216:	e94e                	sd	s3,144(sp)
    80006218:	ed52                	sd	s4,152(sp)
    8000621a:	f156                	sd	s5,160(sp)
    8000621c:	f55a                	sd	s6,168(sp)
    8000621e:	f95e                	sd	s7,176(sp)
    80006220:	fd62                	sd	s8,184(sp)
    80006222:	e1e6                	sd	s9,192(sp)
    80006224:	e5ea                	sd	s10,200(sp)
    80006226:	e9ee                	sd	s11,208(sp)
    80006228:	edf2                	sd	t3,216(sp)
    8000622a:	f1f6                	sd	t4,224(sp)
    8000622c:	f5fa                	sd	t5,232(sp)
    8000622e:	f9fe                	sd	t6,240(sp)
    80006230:	c6bfc0ef          	jal	ra,80002e9a <kerneltrap>
    80006234:	6082                	ld	ra,0(sp)
    80006236:	6122                	ld	sp,8(sp)
    80006238:	61c2                	ld	gp,16(sp)
    8000623a:	7282                	ld	t0,32(sp)
    8000623c:	7322                	ld	t1,40(sp)
    8000623e:	73c2                	ld	t2,48(sp)
    80006240:	7462                	ld	s0,56(sp)
    80006242:	6486                	ld	s1,64(sp)
    80006244:	6526                	ld	a0,72(sp)
    80006246:	65c6                	ld	a1,80(sp)
    80006248:	6666                	ld	a2,88(sp)
    8000624a:	7686                	ld	a3,96(sp)
    8000624c:	7726                	ld	a4,104(sp)
    8000624e:	77c6                	ld	a5,112(sp)
    80006250:	7866                	ld	a6,120(sp)
    80006252:	688a                	ld	a7,128(sp)
    80006254:	692a                	ld	s2,136(sp)
    80006256:	69ca                	ld	s3,144(sp)
    80006258:	6a6a                	ld	s4,152(sp)
    8000625a:	7a8a                	ld	s5,160(sp)
    8000625c:	7b2a                	ld	s6,168(sp)
    8000625e:	7bca                	ld	s7,176(sp)
    80006260:	7c6a                	ld	s8,184(sp)
    80006262:	6c8e                	ld	s9,192(sp)
    80006264:	6d2e                	ld	s10,200(sp)
    80006266:	6dce                	ld	s11,208(sp)
    80006268:	6e6e                	ld	t3,216(sp)
    8000626a:	7e8e                	ld	t4,224(sp)
    8000626c:	7f2e                	ld	t5,232(sp)
    8000626e:	7fce                	ld	t6,240(sp)
    80006270:	6111                	addi	sp,sp,256
    80006272:	10200073          	sret
    80006276:	00000013          	nop
    8000627a:	00000013          	nop
    8000627e:	0001                	nop

0000000080006280 <timervec>:
    80006280:	34051573          	csrrw	a0,mscratch,a0
    80006284:	e10c                	sd	a1,0(a0)
    80006286:	e510                	sd	a2,8(a0)
    80006288:	e914                	sd	a3,16(a0)
    8000628a:	6d0c                	ld	a1,24(a0)
    8000628c:	7110                	ld	a2,32(a0)
    8000628e:	6194                	ld	a3,0(a1)
    80006290:	96b2                	add	a3,a3,a2
    80006292:	e194                	sd	a3,0(a1)
    80006294:	4589                	li	a1,2
    80006296:	14459073          	csrw	sip,a1
    8000629a:	6914                	ld	a3,16(a0)
    8000629c:	6510                	ld	a2,8(a0)
    8000629e:	610c                	ld	a1,0(a0)
    800062a0:	34051573          	csrrw	a0,mscratch,a0
    800062a4:	30200073          	mret
	...

00000000800062aa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800062aa:	1141                	addi	sp,sp,-16
    800062ac:	e422                	sd	s0,8(sp)
    800062ae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800062b0:	0c0007b7          	lui	a5,0xc000
    800062b4:	4705                	li	a4,1
    800062b6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800062b8:	c3d8                	sw	a4,4(a5)
}
    800062ba:	6422                	ld	s0,8(sp)
    800062bc:	0141                	addi	sp,sp,16
    800062be:	8082                	ret

00000000800062c0 <plicinithart>:

void
plicinithart(void)
{
    800062c0:	1141                	addi	sp,sp,-16
    800062c2:	e406                	sd	ra,8(sp)
    800062c4:	e022                	sd	s0,0(sp)
    800062c6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062c8:	ffffb097          	auipc	ra,0xffffb
    800062cc:	6c0080e7          	jalr	1728(ra) # 80001988 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062d0:	0085171b          	slliw	a4,a0,0x8
    800062d4:	0c0027b7          	lui	a5,0xc002
    800062d8:	97ba                	add	a5,a5,a4
    800062da:	40200713          	li	a4,1026
    800062de:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800062e2:	00d5151b          	slliw	a0,a0,0xd
    800062e6:	0c2017b7          	lui	a5,0xc201
    800062ea:	953e                	add	a0,a0,a5
    800062ec:	00052023          	sw	zero,0(a0)
}
    800062f0:	60a2                	ld	ra,8(sp)
    800062f2:	6402                	ld	s0,0(sp)
    800062f4:	0141                	addi	sp,sp,16
    800062f6:	8082                	ret

00000000800062f8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800062f8:	1141                	addi	sp,sp,-16
    800062fa:	e406                	sd	ra,8(sp)
    800062fc:	e022                	sd	s0,0(sp)
    800062fe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006300:	ffffb097          	auipc	ra,0xffffb
    80006304:	688080e7          	jalr	1672(ra) # 80001988 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006308:	00d5179b          	slliw	a5,a0,0xd
    8000630c:	0c201537          	lui	a0,0xc201
    80006310:	953e                	add	a0,a0,a5
  return irq;
}
    80006312:	4148                	lw	a0,4(a0)
    80006314:	60a2                	ld	ra,8(sp)
    80006316:	6402                	ld	s0,0(sp)
    80006318:	0141                	addi	sp,sp,16
    8000631a:	8082                	ret

000000008000631c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000631c:	1101                	addi	sp,sp,-32
    8000631e:	ec06                	sd	ra,24(sp)
    80006320:	e822                	sd	s0,16(sp)
    80006322:	e426                	sd	s1,8(sp)
    80006324:	1000                	addi	s0,sp,32
    80006326:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006328:	ffffb097          	auipc	ra,0xffffb
    8000632c:	660080e7          	jalr	1632(ra) # 80001988 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006330:	00d5151b          	slliw	a0,a0,0xd
    80006334:	0c2017b7          	lui	a5,0xc201
    80006338:	97aa                	add	a5,a5,a0
    8000633a:	c3c4                	sw	s1,4(a5)
}
    8000633c:	60e2                	ld	ra,24(sp)
    8000633e:	6442                	ld	s0,16(sp)
    80006340:	64a2                	ld	s1,8(sp)
    80006342:	6105                	addi	sp,sp,32
    80006344:	8082                	ret

0000000080006346 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006346:	1141                	addi	sp,sp,-16
    80006348:	e406                	sd	ra,8(sp)
    8000634a:	e022                	sd	s0,0(sp)
    8000634c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000634e:	479d                	li	a5,7
    80006350:	04a7cc63          	blt	a5,a0,800063a8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006354:	0001d797          	auipc	a5,0x1d
    80006358:	afc78793          	addi	a5,a5,-1284 # 80022e50 <disk>
    8000635c:	97aa                	add	a5,a5,a0
    8000635e:	0187c783          	lbu	a5,24(a5)
    80006362:	ebb9                	bnez	a5,800063b8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006364:	00451613          	slli	a2,a0,0x4
    80006368:	0001d797          	auipc	a5,0x1d
    8000636c:	ae878793          	addi	a5,a5,-1304 # 80022e50 <disk>
    80006370:	6394                	ld	a3,0(a5)
    80006372:	96b2                	add	a3,a3,a2
    80006374:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006378:	6398                	ld	a4,0(a5)
    8000637a:	9732                	add	a4,a4,a2
    8000637c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006380:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006384:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006388:	953e                	add	a0,a0,a5
    8000638a:	4785                	li	a5,1
    8000638c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006390:	0001d517          	auipc	a0,0x1d
    80006394:	ad850513          	addi	a0,a0,-1320 # 80022e68 <disk+0x18>
    80006398:	ffffc097          	auipc	ra,0xffffc
    8000639c:	d30080e7          	jalr	-720(ra) # 800020c8 <wakeup>
}
    800063a0:	60a2                	ld	ra,8(sp)
    800063a2:	6402                	ld	s0,0(sp)
    800063a4:	0141                	addi	sp,sp,16
    800063a6:	8082                	ret
    panic("free_desc 1");
    800063a8:	00002517          	auipc	a0,0x2
    800063ac:	3c050513          	addi	a0,a0,960 # 80008768 <syscalls+0x318>
    800063b0:	ffffa097          	auipc	ra,0xffffa
    800063b4:	18e080e7          	jalr	398(ra) # 8000053e <panic>
    panic("free_desc 2");
    800063b8:	00002517          	auipc	a0,0x2
    800063bc:	3c050513          	addi	a0,a0,960 # 80008778 <syscalls+0x328>
    800063c0:	ffffa097          	auipc	ra,0xffffa
    800063c4:	17e080e7          	jalr	382(ra) # 8000053e <panic>

00000000800063c8 <virtio_disk_init>:
{
    800063c8:	1101                	addi	sp,sp,-32
    800063ca:	ec06                	sd	ra,24(sp)
    800063cc:	e822                	sd	s0,16(sp)
    800063ce:	e426                	sd	s1,8(sp)
    800063d0:	e04a                	sd	s2,0(sp)
    800063d2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800063d4:	00002597          	auipc	a1,0x2
    800063d8:	3b458593          	addi	a1,a1,948 # 80008788 <syscalls+0x338>
    800063dc:	0001d517          	auipc	a0,0x1d
    800063e0:	b9c50513          	addi	a0,a0,-1124 # 80022f78 <disk+0x128>
    800063e4:	ffffa097          	auipc	ra,0xffffa
    800063e8:	762080e7          	jalr	1890(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063ec:	100017b7          	lui	a5,0x10001
    800063f0:	4398                	lw	a4,0(a5)
    800063f2:	2701                	sext.w	a4,a4
    800063f4:	747277b7          	lui	a5,0x74727
    800063f8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800063fc:	14f71c63          	bne	a4,a5,80006554 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006400:	100017b7          	lui	a5,0x10001
    80006404:	43dc                	lw	a5,4(a5)
    80006406:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006408:	4709                	li	a4,2
    8000640a:	14e79563          	bne	a5,a4,80006554 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000640e:	100017b7          	lui	a5,0x10001
    80006412:	479c                	lw	a5,8(a5)
    80006414:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006416:	12e79f63          	bne	a5,a4,80006554 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000641a:	100017b7          	lui	a5,0x10001
    8000641e:	47d8                	lw	a4,12(a5)
    80006420:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006422:	554d47b7          	lui	a5,0x554d4
    80006426:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000642a:	12f71563          	bne	a4,a5,80006554 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000642e:	100017b7          	lui	a5,0x10001
    80006432:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006436:	4705                	li	a4,1
    80006438:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000643a:	470d                	li	a4,3
    8000643c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000643e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006440:	c7ffe737          	lui	a4,0xc7ffe
    80006444:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdb7cf>
    80006448:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000644a:	2701                	sext.w	a4,a4
    8000644c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000644e:	472d                	li	a4,11
    80006450:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006452:	5bbc                	lw	a5,112(a5)
    80006454:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006458:	8ba1                	andi	a5,a5,8
    8000645a:	10078563          	beqz	a5,80006564 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000645e:	100017b7          	lui	a5,0x10001
    80006462:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006466:	43fc                	lw	a5,68(a5)
    80006468:	2781                	sext.w	a5,a5
    8000646a:	10079563          	bnez	a5,80006574 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000646e:	100017b7          	lui	a5,0x10001
    80006472:	5bdc                	lw	a5,52(a5)
    80006474:	2781                	sext.w	a5,a5
  if(max == 0)
    80006476:	10078763          	beqz	a5,80006584 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000647a:	471d                	li	a4,7
    8000647c:	10f77c63          	bgeu	a4,a5,80006594 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006480:	ffffa097          	auipc	ra,0xffffa
    80006484:	666080e7          	jalr	1638(ra) # 80000ae6 <kalloc>
    80006488:	0001d497          	auipc	s1,0x1d
    8000648c:	9c848493          	addi	s1,s1,-1592 # 80022e50 <disk>
    80006490:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006492:	ffffa097          	auipc	ra,0xffffa
    80006496:	654080e7          	jalr	1620(ra) # 80000ae6 <kalloc>
    8000649a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000649c:	ffffa097          	auipc	ra,0xffffa
    800064a0:	64a080e7          	jalr	1610(ra) # 80000ae6 <kalloc>
    800064a4:	87aa                	mv	a5,a0
    800064a6:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800064a8:	6088                	ld	a0,0(s1)
    800064aa:	cd6d                	beqz	a0,800065a4 <virtio_disk_init+0x1dc>
    800064ac:	0001d717          	auipc	a4,0x1d
    800064b0:	9ac73703          	ld	a4,-1620(a4) # 80022e58 <disk+0x8>
    800064b4:	cb65                	beqz	a4,800065a4 <virtio_disk_init+0x1dc>
    800064b6:	c7fd                	beqz	a5,800065a4 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    800064b8:	6605                	lui	a2,0x1
    800064ba:	4581                	li	a1,0
    800064bc:	ffffb097          	auipc	ra,0xffffb
    800064c0:	816080e7          	jalr	-2026(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800064c4:	0001d497          	auipc	s1,0x1d
    800064c8:	98c48493          	addi	s1,s1,-1652 # 80022e50 <disk>
    800064cc:	6605                	lui	a2,0x1
    800064ce:	4581                	li	a1,0
    800064d0:	6488                	ld	a0,8(s1)
    800064d2:	ffffb097          	auipc	ra,0xffffb
    800064d6:	800080e7          	jalr	-2048(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800064da:	6605                	lui	a2,0x1
    800064dc:	4581                	li	a1,0
    800064de:	6888                	ld	a0,16(s1)
    800064e0:	ffffa097          	auipc	ra,0xffffa
    800064e4:	7f2080e7          	jalr	2034(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800064e8:	100017b7          	lui	a5,0x10001
    800064ec:	4721                	li	a4,8
    800064ee:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800064f0:	4098                	lw	a4,0(s1)
    800064f2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800064f6:	40d8                	lw	a4,4(s1)
    800064f8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800064fc:	6498                	ld	a4,8(s1)
    800064fe:	0007069b          	sext.w	a3,a4
    80006502:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006506:	9701                	srai	a4,a4,0x20
    80006508:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000650c:	6898                	ld	a4,16(s1)
    8000650e:	0007069b          	sext.w	a3,a4
    80006512:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006516:	9701                	srai	a4,a4,0x20
    80006518:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000651c:	4705                	li	a4,1
    8000651e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006520:	00e48c23          	sb	a4,24(s1)
    80006524:	00e48ca3          	sb	a4,25(s1)
    80006528:	00e48d23          	sb	a4,26(s1)
    8000652c:	00e48da3          	sb	a4,27(s1)
    80006530:	00e48e23          	sb	a4,28(s1)
    80006534:	00e48ea3          	sb	a4,29(s1)
    80006538:	00e48f23          	sb	a4,30(s1)
    8000653c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006540:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006544:	0727a823          	sw	s2,112(a5)
}
    80006548:	60e2                	ld	ra,24(sp)
    8000654a:	6442                	ld	s0,16(sp)
    8000654c:	64a2                	ld	s1,8(sp)
    8000654e:	6902                	ld	s2,0(sp)
    80006550:	6105                	addi	sp,sp,32
    80006552:	8082                	ret
    panic("could not find virtio disk");
    80006554:	00002517          	auipc	a0,0x2
    80006558:	24450513          	addi	a0,a0,580 # 80008798 <syscalls+0x348>
    8000655c:	ffffa097          	auipc	ra,0xffffa
    80006560:	fe2080e7          	jalr	-30(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006564:	00002517          	auipc	a0,0x2
    80006568:	25450513          	addi	a0,a0,596 # 800087b8 <syscalls+0x368>
    8000656c:	ffffa097          	auipc	ra,0xffffa
    80006570:	fd2080e7          	jalr	-46(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006574:	00002517          	auipc	a0,0x2
    80006578:	26450513          	addi	a0,a0,612 # 800087d8 <syscalls+0x388>
    8000657c:	ffffa097          	auipc	ra,0xffffa
    80006580:	fc2080e7          	jalr	-62(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006584:	00002517          	auipc	a0,0x2
    80006588:	27450513          	addi	a0,a0,628 # 800087f8 <syscalls+0x3a8>
    8000658c:	ffffa097          	auipc	ra,0xffffa
    80006590:	fb2080e7          	jalr	-78(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006594:	00002517          	auipc	a0,0x2
    80006598:	28450513          	addi	a0,a0,644 # 80008818 <syscalls+0x3c8>
    8000659c:	ffffa097          	auipc	ra,0xffffa
    800065a0:	fa2080e7          	jalr	-94(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    800065a4:	00002517          	auipc	a0,0x2
    800065a8:	29450513          	addi	a0,a0,660 # 80008838 <syscalls+0x3e8>
    800065ac:	ffffa097          	auipc	ra,0xffffa
    800065b0:	f92080e7          	jalr	-110(ra) # 8000053e <panic>

00000000800065b4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800065b4:	7119                	addi	sp,sp,-128
    800065b6:	fc86                	sd	ra,120(sp)
    800065b8:	f8a2                	sd	s0,112(sp)
    800065ba:	f4a6                	sd	s1,104(sp)
    800065bc:	f0ca                	sd	s2,96(sp)
    800065be:	ecce                	sd	s3,88(sp)
    800065c0:	e8d2                	sd	s4,80(sp)
    800065c2:	e4d6                	sd	s5,72(sp)
    800065c4:	e0da                	sd	s6,64(sp)
    800065c6:	fc5e                	sd	s7,56(sp)
    800065c8:	f862                	sd	s8,48(sp)
    800065ca:	f466                	sd	s9,40(sp)
    800065cc:	f06a                	sd	s10,32(sp)
    800065ce:	ec6e                	sd	s11,24(sp)
    800065d0:	0100                	addi	s0,sp,128
    800065d2:	8aaa                	mv	s5,a0
    800065d4:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800065d6:	00c52d03          	lw	s10,12(a0)
    800065da:	001d1d1b          	slliw	s10,s10,0x1
    800065de:	1d02                	slli	s10,s10,0x20
    800065e0:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800065e4:	0001d517          	auipc	a0,0x1d
    800065e8:	99450513          	addi	a0,a0,-1644 # 80022f78 <disk+0x128>
    800065ec:	ffffa097          	auipc	ra,0xffffa
    800065f0:	5ea080e7          	jalr	1514(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800065f4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800065f6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800065f8:	0001db97          	auipc	s7,0x1d
    800065fc:	858b8b93          	addi	s7,s7,-1960 # 80022e50 <disk>
  for(int i = 0; i < 3; i++){
    80006600:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006602:	0001dc97          	auipc	s9,0x1d
    80006606:	976c8c93          	addi	s9,s9,-1674 # 80022f78 <disk+0x128>
    8000660a:	a08d                	j	8000666c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000660c:	00fb8733          	add	a4,s7,a5
    80006610:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006614:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006616:	0207c563          	bltz	a5,80006640 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000661a:	2905                	addiw	s2,s2,1
    8000661c:	0611                	addi	a2,a2,4
    8000661e:	05690c63          	beq	s2,s6,80006676 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006622:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006624:	0001d717          	auipc	a4,0x1d
    80006628:	82c70713          	addi	a4,a4,-2004 # 80022e50 <disk>
    8000662c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000662e:	01874683          	lbu	a3,24(a4)
    80006632:	fee9                	bnez	a3,8000660c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006634:	2785                	addiw	a5,a5,1
    80006636:	0705                	addi	a4,a4,1
    80006638:	fe979be3          	bne	a5,s1,8000662e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000663c:	57fd                	li	a5,-1
    8000663e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006640:	01205d63          	blez	s2,8000665a <virtio_disk_rw+0xa6>
    80006644:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006646:	000a2503          	lw	a0,0(s4)
    8000664a:	00000097          	auipc	ra,0x0
    8000664e:	cfc080e7          	jalr	-772(ra) # 80006346 <free_desc>
      for(int j = 0; j < i; j++)
    80006652:	2d85                	addiw	s11,s11,1
    80006654:	0a11                	addi	s4,s4,4
    80006656:	ffb918e3          	bne	s2,s11,80006646 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000665a:	85e6                	mv	a1,s9
    8000665c:	0001d517          	auipc	a0,0x1d
    80006660:	80c50513          	addi	a0,a0,-2036 # 80022e68 <disk+0x18>
    80006664:	ffffc097          	auipc	ra,0xffffc
    80006668:	a00080e7          	jalr	-1536(ra) # 80002064 <sleep>
  for(int i = 0; i < 3; i++){
    8000666c:	f8040a13          	addi	s4,s0,-128
{
    80006670:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006672:	894e                	mv	s2,s3
    80006674:	b77d                	j	80006622 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006676:	f8042583          	lw	a1,-128(s0)
    8000667a:	00a58793          	addi	a5,a1,10
    8000667e:	0792                	slli	a5,a5,0x4

  if(write)
    80006680:	0001c617          	auipc	a2,0x1c
    80006684:	7d060613          	addi	a2,a2,2000 # 80022e50 <disk>
    80006688:	00f60733          	add	a4,a2,a5
    8000668c:	018036b3          	snez	a3,s8
    80006690:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006692:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006696:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000669a:	f6078693          	addi	a3,a5,-160
    8000669e:	6218                	ld	a4,0(a2)
    800066a0:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066a2:	00878513          	addi	a0,a5,8
    800066a6:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800066a8:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800066aa:	6208                	ld	a0,0(a2)
    800066ac:	96aa                	add	a3,a3,a0
    800066ae:	4741                	li	a4,16
    800066b0:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800066b2:	4705                	li	a4,1
    800066b4:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800066b8:	f8442703          	lw	a4,-124(s0)
    800066bc:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800066c0:	0712                	slli	a4,a4,0x4
    800066c2:	953a                	add	a0,a0,a4
    800066c4:	058a8693          	addi	a3,s5,88
    800066c8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800066ca:	6208                	ld	a0,0(a2)
    800066cc:	972a                	add	a4,a4,a0
    800066ce:	40000693          	li	a3,1024
    800066d2:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800066d4:	001c3c13          	seqz	s8,s8
    800066d8:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800066da:	001c6c13          	ori	s8,s8,1
    800066de:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800066e2:	f8842603          	lw	a2,-120(s0)
    800066e6:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800066ea:	0001c697          	auipc	a3,0x1c
    800066ee:	76668693          	addi	a3,a3,1894 # 80022e50 <disk>
    800066f2:	00258713          	addi	a4,a1,2
    800066f6:	0712                	slli	a4,a4,0x4
    800066f8:	9736                	add	a4,a4,a3
    800066fa:	587d                	li	a6,-1
    800066fc:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006700:	0612                	slli	a2,a2,0x4
    80006702:	9532                	add	a0,a0,a2
    80006704:	f9078793          	addi	a5,a5,-112
    80006708:	97b6                	add	a5,a5,a3
    8000670a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000670c:	629c                	ld	a5,0(a3)
    8000670e:	97b2                	add	a5,a5,a2
    80006710:	4605                	li	a2,1
    80006712:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006714:	4509                	li	a0,2
    80006716:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000671a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000671e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006722:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006726:	6698                	ld	a4,8(a3)
    80006728:	00275783          	lhu	a5,2(a4)
    8000672c:	8b9d                	andi	a5,a5,7
    8000672e:	0786                	slli	a5,a5,0x1
    80006730:	97ba                	add	a5,a5,a4
    80006732:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006736:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000673a:	6698                	ld	a4,8(a3)
    8000673c:	00275783          	lhu	a5,2(a4)
    80006740:	2785                	addiw	a5,a5,1
    80006742:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006746:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000674a:	100017b7          	lui	a5,0x10001
    8000674e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006752:	004aa783          	lw	a5,4(s5)
    80006756:	02c79163          	bne	a5,a2,80006778 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000675a:	0001d917          	auipc	s2,0x1d
    8000675e:	81e90913          	addi	s2,s2,-2018 # 80022f78 <disk+0x128>
  while(b->disk == 1) {
    80006762:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006764:	85ca                	mv	a1,s2
    80006766:	8556                	mv	a0,s5
    80006768:	ffffc097          	auipc	ra,0xffffc
    8000676c:	8fc080e7          	jalr	-1796(ra) # 80002064 <sleep>
  while(b->disk == 1) {
    80006770:	004aa783          	lw	a5,4(s5)
    80006774:	fe9788e3          	beq	a5,s1,80006764 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006778:	f8042903          	lw	s2,-128(s0)
    8000677c:	00290793          	addi	a5,s2,2
    80006780:	00479713          	slli	a4,a5,0x4
    80006784:	0001c797          	auipc	a5,0x1c
    80006788:	6cc78793          	addi	a5,a5,1740 # 80022e50 <disk>
    8000678c:	97ba                	add	a5,a5,a4
    8000678e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006792:	0001c997          	auipc	s3,0x1c
    80006796:	6be98993          	addi	s3,s3,1726 # 80022e50 <disk>
    8000679a:	00491713          	slli	a4,s2,0x4
    8000679e:	0009b783          	ld	a5,0(s3)
    800067a2:	97ba                	add	a5,a5,a4
    800067a4:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800067a8:	854a                	mv	a0,s2
    800067aa:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800067ae:	00000097          	auipc	ra,0x0
    800067b2:	b98080e7          	jalr	-1128(ra) # 80006346 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800067b6:	8885                	andi	s1,s1,1
    800067b8:	f0ed                	bnez	s1,8000679a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800067ba:	0001c517          	auipc	a0,0x1c
    800067be:	7be50513          	addi	a0,a0,1982 # 80022f78 <disk+0x128>
    800067c2:	ffffa097          	auipc	ra,0xffffa
    800067c6:	4c8080e7          	jalr	1224(ra) # 80000c8a <release>
}
    800067ca:	70e6                	ld	ra,120(sp)
    800067cc:	7446                	ld	s0,112(sp)
    800067ce:	74a6                	ld	s1,104(sp)
    800067d0:	7906                	ld	s2,96(sp)
    800067d2:	69e6                	ld	s3,88(sp)
    800067d4:	6a46                	ld	s4,80(sp)
    800067d6:	6aa6                	ld	s5,72(sp)
    800067d8:	6b06                	ld	s6,64(sp)
    800067da:	7be2                	ld	s7,56(sp)
    800067dc:	7c42                	ld	s8,48(sp)
    800067de:	7ca2                	ld	s9,40(sp)
    800067e0:	7d02                	ld	s10,32(sp)
    800067e2:	6de2                	ld	s11,24(sp)
    800067e4:	6109                	addi	sp,sp,128
    800067e6:	8082                	ret

00000000800067e8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800067e8:	1101                	addi	sp,sp,-32
    800067ea:	ec06                	sd	ra,24(sp)
    800067ec:	e822                	sd	s0,16(sp)
    800067ee:	e426                	sd	s1,8(sp)
    800067f0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800067f2:	0001c497          	auipc	s1,0x1c
    800067f6:	65e48493          	addi	s1,s1,1630 # 80022e50 <disk>
    800067fa:	0001c517          	auipc	a0,0x1c
    800067fe:	77e50513          	addi	a0,a0,1918 # 80022f78 <disk+0x128>
    80006802:	ffffa097          	auipc	ra,0xffffa
    80006806:	3d4080e7          	jalr	980(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000680a:	10001737          	lui	a4,0x10001
    8000680e:	533c                	lw	a5,96(a4)
    80006810:	8b8d                	andi	a5,a5,3
    80006812:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006814:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006818:	689c                	ld	a5,16(s1)
    8000681a:	0204d703          	lhu	a4,32(s1)
    8000681e:	0027d783          	lhu	a5,2(a5)
    80006822:	04f70863          	beq	a4,a5,80006872 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006826:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000682a:	6898                	ld	a4,16(s1)
    8000682c:	0204d783          	lhu	a5,32(s1)
    80006830:	8b9d                	andi	a5,a5,7
    80006832:	078e                	slli	a5,a5,0x3
    80006834:	97ba                	add	a5,a5,a4
    80006836:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006838:	00278713          	addi	a4,a5,2
    8000683c:	0712                	slli	a4,a4,0x4
    8000683e:	9726                	add	a4,a4,s1
    80006840:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006844:	e721                	bnez	a4,8000688c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006846:	0789                	addi	a5,a5,2
    80006848:	0792                	slli	a5,a5,0x4
    8000684a:	97a6                	add	a5,a5,s1
    8000684c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000684e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006852:	ffffc097          	auipc	ra,0xffffc
    80006856:	876080e7          	jalr	-1930(ra) # 800020c8 <wakeup>

    disk.used_idx += 1;
    8000685a:	0204d783          	lhu	a5,32(s1)
    8000685e:	2785                	addiw	a5,a5,1
    80006860:	17c2                	slli	a5,a5,0x30
    80006862:	93c1                	srli	a5,a5,0x30
    80006864:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006868:	6898                	ld	a4,16(s1)
    8000686a:	00275703          	lhu	a4,2(a4)
    8000686e:	faf71ce3          	bne	a4,a5,80006826 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006872:	0001c517          	auipc	a0,0x1c
    80006876:	70650513          	addi	a0,a0,1798 # 80022f78 <disk+0x128>
    8000687a:	ffffa097          	auipc	ra,0xffffa
    8000687e:	410080e7          	jalr	1040(ra) # 80000c8a <release>
}
    80006882:	60e2                	ld	ra,24(sp)
    80006884:	6442                	ld	s0,16(sp)
    80006886:	64a2                	ld	s1,8(sp)
    80006888:	6105                	addi	sp,sp,32
    8000688a:	8082                	ret
      panic("virtio_disk_intr status");
    8000688c:	00002517          	auipc	a0,0x2
    80006890:	fc450513          	addi	a0,a0,-60 # 80008850 <syscalls+0x400>
    80006894:	ffffa097          	auipc	ra,0xffffa
    80006898:	caa080e7          	jalr	-854(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
