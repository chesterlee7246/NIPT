# NIPT分析SOP 

NIPT（无创产前检测，Non-incasive Prenatal Testing）本公司分析流程流程完整的记录位于gitlab上，本文为使用方法

## 一、获取代码库 

1、可克隆git代码库至服务器：

首先克隆该仓库的代码前需要保证你拥有可以使用该仓库的权限

1. 用ssh方式进行克隆 

   ```shell
   git clone git@172.16.10.36:basecare-workflow1/NIPT.git
   ```

2. 用http方式进行克隆 

   ```shell
   git clone http://172.16.10.36/basecare-workflow1/NIPT.git 
   ```

仓库克隆完成后在拥有站点插件返回数据后可直接进行数据分析【使用**主分支**进行数据分析】。

2、代码结构：

```project
└── NIPT
    ├── auto_NIPT_analysis.py
    ├── CNV
    ├── config	├── api.db
				├── mail.txt
				└── site_dict.json
    ├── EGEL
    ├── example
    ├── Lib
    ├── NIPT
    ├── NIPT.py
    ├── qsub_nipt_pip.py
    ├── README.md
    ├── run_nipt_qsub_pip.sh
    └── sites_plugins
```



## 二、获取站点插件返回数据分析文件 

插件返回数据文件名一般为：

\[**测序仪名称**\]\_NIPT_MAPQ10_60_NIPT_CHD\_\[**Site**\]\_UR_user_SN2-\_\[str\]\-\[**Run_ID**\].csv\_\[str]

str 为测序仪上机产生的顺序计数*

在分析某一个站点的某一个上机数据时，首先先确认站点名称和上机单号。

示例文件名称

- saiye-nantong_F04W2Y1_NIPT_MAPQ10_60_NIPT_CHD\_**NanTong**\_UR_Basecare2_SAI-1625-**SQR210125002**_1835_3504.zip



 ## 三 、流程分析

得到站点插件返回数据后，可对该返回的样本进行分析

**1** 、 解压文件至你的分析路径  

```shell
unzip  saiye-nantong_F04W2Y1_NIPT_MAPQ10_60_NIPT_CHD_NanTong_UR_Basecare2_SAI-1625-SQR210125002_1835_3504.zip -d  saiye-nantong_F04W2Y1_NIPT_MAPQ10_60_NIPT_CHD_NanTong_UR_Basecare2_SAI-1625-SQR210125002_1835_3504
```

**2**、 开始分析 

```shell
python NIPT.py  -i analysis_dir -s Site_name[NanTong/ShengJing/XuZhou/JiaYin/LinYi/...] -p  pip_name[full/analysis/upload/report]
```

full：包括analysis、upload 、report 

analysis：对站点返回Run数据内的样本进行NIPT的分析

report：针对各站点分析结果进行质控邮件统计并将质控结果导入质控数据库（report 必须在analysis后）

upload：将该目录下的分析样本的分析结果导入lims系统（upload 必须在analysis 后 ）

参数 -i 、-s 为必选项，-p 默认 full 

若要使用report模块（包括analysis和report模块），则需要对发送的邮件的信息进行配置，配置文件为

- config/mai.txt

  ![image-20210128162348240](https://i.loli.net/2021/01/29/ZnIQ6EocFi4Ujvb.png)

  该文件内配置的内容为report分析中发送质控邮件的信息，包括站点名称，发送人，收件人和抄送人

  若site_dict中的站点名称在mail配置文件中不存在，则该质控结果不能发送质控邮件和导入质控数据库

分析示例：

```shell
python NIPT.py -i  saiye-nantong_F04W2Y1_NIPT_MAPQ10_60_NIPT_CHD_NanTong_UR_Basecare2_SAI-1625-SQR210125002_1835_3504 -s NanTong -p full 
```

**3**、报错提示

**3.1**若分析报错为 

![image-20210128110350015](https://i.loli.net/2021/01/29/HrO86tL1piYavCn.png)

可查看分析目录下index2id_tmp.txt 和index2id.txt文件的内容来排报错原因。如果index2id.txt没有内容，而index2id_tmp.txt 中有内容，则有可能是session_id过期或者错误，解决方法为删除config/api.db 后再运行，会重新获取session_id并写入文件config/api.db中，继续开始分析。

**4**、NIPT分析流程在日常的分析中已启用自动分析，配置好各个参数和文件，即可使用自动分析流程

配置文件：

- site_dict.json

![image-20210128162403693](https://i.loli.net/2021/01/29/MgrnbacmpEKVG2t.png)

该文件内配置的内容为站点插件返回的文件名，一般同一台测序仪的前缀相同，key为文件前缀，value为对应某个站点

配置好该文件后可运行脚本：

```shell
 python auto_NIPT_analysis.py data_dir pip_dir analysis_dir site_dict_config_file
```

data_dir：站点插件返回数据保存目录

pip_dir：流程分析脚本所在目录

analysis_dir：分析目录（该目录下提前建好site_dict中的站点名称目录）

site_dict_config_file：配置的站点插件结果文件前缀和对应的站点名称

执行该自动分析脚本后，当站点有新返回的数据，可进行自动分析，该自动分析的 NIPT.py 的 -p 参数为 full



##  四、分析结果解读

针对analysis分析过程完成的结果，包括样本的NIPT结果和对应的NIPT数据的CNV结果

### NIPT结果

**1**、各样本数据量 unique_reads

- IonXpress\_\[**index**\]\_rawlib_rmdup_MAPQ10_Nbin.txt

第一行为unique _reads 的大小

![image-20210128150352299](https://i.loli.net/2021/01/29/En9T7vqjeCUcBhb.png)

- IonXpress\_\[**index**\]\__BamDuplicates.json

  该文件中有包含该样本其他reads的统计，包括 dup_reads，total_reads

![image-20210128150315794](https://i.loli.net/2021/01/29/cFJZQb1zTjBMEDU.png)

**2**、各染色体的Z值文件

常规样本：

- IonXpress\_\[**index**\]\_rawlib_rmdup_MAPQ60_Fbin_GC_Per_ZScore.txt

![image-20210128150549379](https://i.loli.net/2021/01/29/Zjv2OnqpAWkecE3.png)

富集样本：

- IonXpress\_[**index**\]\_rawlib_rmdup_MAPQ60_2000Kb_Fbin_GC_All_Normalized_Percentage_ZScore.txt

![image-20210128150856161](https://i.loli.net/2021/01/29/lJAIGQ7SgDEqOrN.png)

**3**、预测胎儿浓度文件

常规样本：

-  IonXpress\_[**index**\]\_rawlibdup_Size_Info_Percentage.txt

![image-20210128150437347](https://i.loli.net/2021/01/29/ihKI8dYMRajZmnJ.png)

富集样本：

- IonXpress\_[**index**\]\_SeqFF_Fetal.txt 

![image-20210128150507954](https://i.loli.net/2021/01/29/q2nOrliheEtfJP1.png)

在预测胎儿浓度文件的最后一行为预测胎儿浓度，如为男胎样本，可在Z值结果文件第一行找到基于Y计算的胎儿浓度。

**4**、各样本各染色体的NIPT小区域Z值分布折线图

常规样本：

-  IonXpress\_[**index**\]\_rawlib_rmdup_MAPQ60_Fbin_GC_All_Merge_ZScore_FLasso_Value_FLasso.html

![image-20210128145749745](https://i.loli.net/2021/01/29/uKg14J6UmBC5DOS.png)

富集样本：

- IonXpress\_[**index**\]\_rawlib_rmdup_MAPQ60_Fbin_GC_All_2000Kb_Merge_ZScore_FLasso_Value_FLasso.html

![image-20210129142609307](upload\image-20210129142609307.png)

针对南通站点，还有一个全部染色体Z值的散点+折现图

- IonXpress\_[**index**\]\_rawlib_rmdup_MAPQ60_Fbin_GC_All_Merge_ZScore_FLasso_Value_FLasso.png
![image-20210129142725778](https://i.loli.net/2021/01/29/MbVgn1GdrIqStfB.png)

**5**、六个微缺失区域的的Z值

常规样本：

- IonXpress\_[**index**\]_rawlib_rmdup_MAPQ60_Fbin_GC_Per_MicroInDel_ZScore.txt

![image-20210128151119518](https://i.loli.net/2021/01/29/CgdoOcnx4uS79EA.png)

富集样本：

- IonXpress\_[**index**\]_rawlib_rmdup_MAPQ60_Fbin_GC_All_MicroInDel_ZScore.txt

![image-20210128154429387](https://i.loli.net/2021/01/29/Zhn5j7Ocg1qa86v.png)

文件最后一列为对应的区域的Z值，这6个微缺失区域涉及的综合征如下：

| 综合征                   | 涉及染色体 |
| ------------------------ | ---------- |
| 22q11.2 deletion  综合征 | chr22      |
| 1p36 deletion 综合征     | chr1       |
| 2q33.1 deletion s综合征  | chr2       |
| Cri du Chat 综合征       | chr5       |
| Langer Giedion 综合征    | chr8       |
| Angelman syndrome        | chr15      |
| Prader Willi 综合征      | chr15      |

**6**、对于染色体上大于10Mb区域的Z值大于4的结果提示

常规样本：

- IonXpress\_[**index**\]_rawlib_rmdup_MAPQ60_Fbin_GC_Per_MicroInDel_ZScore_FLasso_Extract_Abnormal.txt

![image-20210128154933444](https://i.loli.net/2021/01/29/SOnXNQ2zgkRCAmv.png)

富集样本：

- IonXpress\_[**index**\]_rawlib_rmdup_MAPQ60_Fbin_GC_All_MicroInDel_ZScore.txt

![image-20210128155109634](https://i.loli.net/2021/01/29/bd6W2hEx3K8mIGX.png)

文件结果说明

第一列：染色体号

第二列：对应区域长度

第三列：对应区域起始和终止位置

第四列：该区域的Z值



### CNV结果

针对NIPT内的CNV结果，主要用于辅助NIPT分析结果审核

**1**、各染色体的拷贝数散点图和散点使用CBS算法计算的断裂点线图

文件：

- IonXpress\_[**index**\]_rawlib_rmdup_MAPQ10_Fbin_GC_All_Merge_Normalized_LogRR_Extract_CNV_ConvertValue\[\_XY\].png

示例图：

![image-20210129113745488](upload\image-20210129113745488.png)

![image-20210128160134673](https://i.loli.net/2021/01/29/Cs5SyhaEtQkxGKJ.png)

以上两张图片 一张有添加性染色体的信息，一张不添加性染色体信息

**2**、各样本各染色体断裂点记录文件
文件：

- IonXpress\_[**index**\]_100Kb_DNAcopy_Info_CNV_RealCNV_LogRR_Effective.txt

![image-20210128160941978](https://i.loli.net/2021/01/29/CUtNfnYEoKeJVw8.png)

断裂点以一段一段的形式记录在文件中，一条染色体中几条记录，即该染色体即被分成了几段，第六例记录了这一段区域的平均log2RR，可用于计算该区段的嵌合比例

**3**、各样本各染色体log2RR的散点和散点使用CBS算法计算的断裂点线图

文件名： 

- IonXpress\_[**index**\]_rawlib_rmdup_MAPQ10_Fbin_GC_All_Merge_Normalized_LogRR_Extract_CNV_chr[num].png

![image-20210128160553108](https://i.loli.net/2021/01/29/QC4HUfqyYMjDA9J.png)



## 五、存在的问题

1、对于小于10Mb的低嵌合率的CNV不能识别

2、每个站点实验情况不同，进而分析结果不一致，例如市立医院的阳性质控样本的常见三体染色体的Z值偏高（近20）

3、Z值结果中计算的Z值 和2000Kb的合并文件计算出来的Z值不同

![image-20210128105535143](https://i.loli.net/2021/01/29/oDinBP4Wsj7CA8R.png)

![image-20210128105629344](https://i.loli.net/2021/01/29/ScgpQCojKGWPTwF.png)


