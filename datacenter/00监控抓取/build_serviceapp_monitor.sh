

find ./data -ctime +15 | xargs rm -f {}

today=$(date "+%Y%m%d")
/usr/bin/python bin/ServiceAppMonitor.py > data/serviceapp_report_${today}.html 

# ���Ը���php�汾�ķ��ʼ��ű� ����ѯ�����ϣ�
/usr/bin/sogou-mds-syncfile -m service_app_spider -l data/serviceapp_report_${today}.html



