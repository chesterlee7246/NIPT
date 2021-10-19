# CNV-anno

CNV-anno是主要基于ACMG 2019年对拷贝数变异（Copy Number Variation, CNV)的致病性解读技术标准而对CNV致病性相关内容进行注释的一个流程。注释内容包括该CNV区域内包含的：编码蛋白基因数量及名称、单倍剂量不足基因的数量及名称、三倍剂量敏感基因数量及名称、功能缺失基因的数量及名称，Gnomad包含的CNV数量和区域、DGV的CNV和具体CNV区域、DECIPHER的致病性（pathogenic)和可能致病（likely pathogenic)CNV的数量及病例数、Clingen致病性CNV数量及所涉及的CNV。


## 如何获取代码库  
可克隆git代码库至服务器：
1. 用ssh 方式进行克隆
git clone  ssh://git@gitlab.basecare.cn:basecare-workflow2/cnv-anno.git
2. 用http方式进行克隆
git clone http://gitlab.basecare.cn/basecare-workflow2/cnv-anno.git

## 如何运行  

可通过导入模块运行

```python

import sys

sys.path.append(annotate.py所在的文件夹路径)  ##添加模块路径,annotate.py所在的文件夹路径示例"/home/wang344/Pipeline/cnv-anno/scripts"

import annotate

result = annotate.cnv_anno(intermediates文件夹所在路径,'chr22',18880001,21460000,'DEL')  ##以列表形式返回注释结果，intermediates文件夹所在路径示例"/home/wang344/Pipeline/cnv-anno/intermediates"

```

## 注释结果说明
注释结果中共22列数据，每一列数据对应内容已在列名中进行描述
具体列相关内容如下：<br />
1. Chr <br />
2. Start <br />
3. End<br />
4. Length:CNV长度（单位bp)<br />
5. CNV_type:CNV类型（包含DUP:重复，DEL：缺失）<br />
6. 包含的RefSeq编码基因数_基因<br />
7. 涉及的RefSeq编码基因数_基因<br />
8. 包含的DECIPHER编码基因数_基因<br />
9. 涉及的DECIPHER编码基因数_基因<br />
10. 包含的OMIM编码基因数_基因<br />
11. 涉及的OMIM编码基因数_基因<br />
12. 包含的单倍剂量不足基因数_基因<br />
13. 涉及的单倍剂量不足基因数_基因<br />
14. 包含的三倍剂量敏感基因数_基因<br />
15. 涉及的三倍剂量敏感基因数_基因<br />
16. 包含的ACMG功能缺失基因数_基因<br />
17. 涉及的ACMG功能缺失基因数_基因<br />
18. 涉及的GNOMAD频率大于1%且长度不小于50Kb的CNV数_CNV<br />
19. 涉及的DGV频率大于1%的CNV数_CNV<br />
20. 涉及的CinGen致病性CNV数_CNV区域_区域名称<br />
21. 涉及的DECIPHER的致病性CNV数_病例数<br />
22. 涉及的DECIPHER的致病性CNV_病例数<br />
23. 涉及的DECIPHER的致病性CNV对应表型<br />
24. 涉及的DECIPHER的可能致病CNV数_病例数<br />
25. 涉及的DECIPHER的可能致病CNV_病例数<br />
26. 涉及的DECIPHER的可能致病CNV对应表型<br />
27. 涉及的DECIPHER综合征数<br />
28. 涉及的DECIPHER综合征坐标_名称_表型<br />


