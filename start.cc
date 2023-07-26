/*
 * @Author       : Outsider
 * @Date         : 2022-07-08 10:52:32
 * @LastEditors  : Outsider
 * @LastEditTime : 2023-07-26 11:42:20
 * @Description  :
 *************************************
 *      设置CSR寄存器
 *1.设置 mepc为 main(),MPP为 S-mode
 *2.mret后跳转到 main(),并切换为 S-mode
 *************************************
 * @FilePath     : /los-cc/start.cc
 */
extern "C"
{
  void start() {
    for (;;)
      ;
  }
}