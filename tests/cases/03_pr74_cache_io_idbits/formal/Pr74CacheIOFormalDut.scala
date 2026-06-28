package top

import chisel3._
import chisel3.stage._
import chisel3.util._
import chisel3.util.experimental.BoringUtils

import nutcore._

class Pr74CacheIOFormalDut extends Module {
  val io = IO(new Bundle {
    val flush = Input(UInt(2.W))

    val cpu_req_valid = Input(Bool())
    val cpu_req_ready = Output(Bool())
    val cpu_req_addr = Input(UInt(32.W))
    val cpu_req_cmd = Input(UInt(4.W))
    val cpu_req_id = Input(UInt(4.W))

    val cpu_resp_valid = Output(Bool())
    val cpu_resp_ready = Input(Bool())
    val cpu_resp_id = Output(UInt(4.W))

    val mem_req_valid = Output(Bool())
    val mem_req_ready = Input(Bool())
    val mem_resp_valid = Input(Bool())
    val mem_resp_cmd = Input(UInt(4.W))
  })

  implicit val cacheConfig = CacheConfig(
    name = "dcache",
    totalSize = 1,
    ways = 4,
    idBits = 4
  )

  val cache = Module(new Cache)

  cache.io.flush := io.flush

  cache.io.in.req.valid := io.cpu_req_valid
  io.cpu_req_ready := cache.io.in.req.ready
  cache.io.in.req.bits.addr := io.cpu_req_addr
  cache.io.in.req.bits.cmd := io.cpu_req_cmd
  cache.io.in.req.bits.size := "b011".U
  cache.io.in.req.bits.wdata := 0.U
  cache.io.in.req.bits.wmask := Fill(8, 1.U)

  // This is the PR #74 litmus point. The parent commit builds CacheIO.in
  // without idBits, so Option.get fails during elaboration for OOO-style IDs.
  cache.io.in.req.bits.id.get := io.cpu_req_id

  io.cpu_resp_valid := cache.io.in.resp.valid
  cache.io.in.resp.ready := io.cpu_resp_ready
  io.cpu_resp_id := cache.io.in.resp.bits.id.get

  io.mem_req_valid := cache.io.out.mem.req.valid
  cache.io.out.mem.req.ready := io.mem_req_ready
  cache.io.out.mem.resp.valid := io.mem_resp_valid
  cache.io.out.mem.resp.bits.cmd := io.mem_resp_cmd
  cache.io.out.mem.resp.bits.rdata := 0.U

  cache.io.mmio.req.ready := true.B
  cache.io.mmio.resp.valid := false.B
  cache.io.mmio.resp.bits.cmd := 0.U
  cache.io.mmio.resp.bits.rdata := 0.U

  cache.io.out.coh.req.valid := false.B
  cache.io.out.coh.req.bits := 0.U.asTypeOf(cache.io.out.coh.req.bits)
  cache.io.out.coh.resp.ready := true.B

  val perfCntCondMdcacheHit = WireInit(false.B)
  val perfCntCondMdcacheLoss = WireInit(false.B)
  val perfCntCondMdcacheReq = WireInit(false.B)
  val lsuMMIO = WireInit(false.B)
  BoringUtils.addSink(perfCntCondMdcacheHit, "perfCntCondMdcacheHit")
  BoringUtils.addSink(perfCntCondMdcacheLoss, "perfCntCondMdcacheLoss")
  BoringUtils.addSink(perfCntCondMdcacheReq, "perfCntCondMdcacheReq")
  BoringUtils.addSink(lsuMMIO, "lsuMMIO")
}

object Pr74CacheIOFormalMain extends App {
  Settings.settings += ("HasL2cache" -> true)
  Settings.settings += ("HasPrefetch" -> true)
  Settings.settings += ("HasDcache" -> true)
  Settings.settings += ("HasIcache" -> true)
  Settings.settings += ("HasDTLB" -> true)
  Settings.settings += ("HasITLB" -> true)
  Settings.settings += ("IsRV32" -> false)
  Settings.settings += ("EnableOutOfOrderExec" -> true)
  Settings.settings += ("EnableMultiIssue" -> true)
  (new ChiselStage).execute(args, Seq(
    ChiselGeneratorAnnotation(() => new Pr74CacheIOFormalDut))
  )
}
