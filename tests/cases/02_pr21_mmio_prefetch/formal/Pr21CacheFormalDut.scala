package top

import chisel3._
import chisel3.util._
import chisel3.util.experimental.BoringUtils

import bus.simplebus._
import nutcore._

class Pr21CacheFormalDut extends Module {
  val io = IO(new Bundle {
    val flush = Input(UInt(2.W))

    val cpu_req_valid = Input(Bool())
    val cpu_req_ready = Output(Bool())
    val cpu_req_addr = Input(UInt(32.W))
    val cpu_req_cmd = Input(UInt(4.W))
    val cpu_resp_valid = Output(Bool())
    val cpu_resp_ready = Input(Bool())

    val mem_req_valid = Output(Bool())
    val mem_req_ready = Input(Bool())
    val mem_resp_valid = Input(Bool())
    val mem_resp_cmd = Input(UInt(4.W))

    val mmio_req_valid = Output(Bool())
    val mmio_req_ready = Input(Bool())
    val mmio_resp_valid = Input(Bool())
    val mmio_resp_cmd = Input(UInt(4.W))

    val pr21_s2_out_valid = Output(Bool())
    val pr21_s2_out_mmio = Output(Bool())
    val pr21_s2_out_prefetch = Output(Bool())
    val pr21_s3_in_valid = Output(Bool())
    val pr21_s3_in_prefetch = Output(Bool())
    val pr21_cache_empty = Output(Bool())
  })

  val in = Wire(new SimpleBusUC())
  val mmio = Wire(new SimpleBusUC())
  val empty = Wire(Bool())

  implicit val cacheConfig = CacheConfig(
    name = "l2cache",
    totalSize = 1,
    ways = 4,
    cacheLevel = 2
  )
  val cacheOut = Cache(in = in, mmio = Seq(mmio), flush = io.flush, empty = empty, enable = true)

  in.req.valid := io.cpu_req_valid
  io.cpu_req_ready := in.req.ready
  in.req.bits.apply(
    addr = io.cpu_req_addr,
    cmd = io.cpu_req_cmd,
    size = "b011".U,
    wdata = 0.U,
    wmask = Fill(8, 1.U)
  )
  io.cpu_resp_valid := in.resp.valid
  in.resp.ready := io.cpu_resp_ready

  io.mem_req_valid := cacheOut.mem.req.valid
  cacheOut.mem.req.ready := io.mem_req_ready
  cacheOut.mem.resp.valid := io.mem_resp_valid
  cacheOut.mem.resp.bits.cmd := io.mem_resp_cmd
  cacheOut.mem.resp.bits.rdata := 0.U

  io.mmio_req_valid := mmio.req.valid
  mmio.req.ready := io.mmio_req_ready
  mmio.resp.valid := io.mmio_resp_valid
  mmio.resp.bits.cmd := io.mmio_resp_cmd
  mmio.resp.bits.rdata := 0.U

  cacheOut.coh.req.valid := false.B
  cacheOut.coh.req.bits := 0.U.asTypeOf(cacheOut.coh.req.bits)
  cacheOut.coh.resp.ready := true.B

  val s2OutValid = WireInit(false.B)
  val s2OutMmio = WireInit(false.B)
  val s2OutPrefetch = WireInit(false.B)
  val s3InValid = WireInit(false.B)
  val s3InPrefetch = WireInit(false.B)
  BoringUtils.addSink(s2OutValid, "pr21_cache_s2_out_valid")
  BoringUtils.addSink(s2OutMmio, "pr21_cache_s2_out_mmio")
  BoringUtils.addSink(s2OutPrefetch, "pr21_cache_s2_out_prefetch")
  BoringUtils.addSink(s3InValid, "pr21_cache_s3_in_valid")
  BoringUtils.addSink(s3InPrefetch, "pr21_cache_s3_in_prefetch")

  io.pr21_s2_out_valid := s2OutValid
  io.pr21_s2_out_mmio := s2OutMmio
  io.pr21_s2_out_prefetch := s2OutPrefetch
  io.pr21_s3_in_valid := s3InValid
  io.pr21_s3_in_prefetch := s3InPrefetch
  io.pr21_cache_empty := empty
}

object Pr21CacheFormalMain extends App {
  Settings.settings += ("HasL2cache" -> true)
  Settings.settings += ("HasPrefetch" -> true)
  Settings.settings += ("HasDcache" -> true)
  Settings.settings += ("HasIcache" -> true)
  Settings.settings += ("HasDTLB" -> true)
  Settings.settings += ("HasITLB" -> true)
  Settings.settings += ("IsRV32" -> false)
  Settings.settings += ("EnableOutOfOrderExec" -> false)
  Driver.execute(args, () => new Pr21CacheFormalDut)
}
