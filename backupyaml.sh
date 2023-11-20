#!/bin/bash
  
DATA_TIME=`date +%Y-%m-%d-%H-%M-%S`  #每次创建根据时间创建
BACKUP_DIR_BASE=/Users/maqingjie/work/k8s-backup-restore  #备份的目录
CURRENT_BACKUP_DIR=${BACKUP_DIR_BASE}/${DATA_TIME}  #备份的目录
  
NS_LIST=$(kubectl get ns|grep 'Active'|grep otel |awk '{print $1}')  # 指定需要备份的namespaces，也可以使用kubectl获取所有，按需
#NS_LIST="tools"
#CONFIG_TYPE="service deploy configmap secret job cronjob replicaset daemonset statefulset"
CONFIG_TYPE="svc deploy ingress cm secret statefulsets pvc"   # 指定namespaces下需要备份的资源类型，按需
CURRENT_DIR=$(cd $(dirname $0); pwd)
 
 
ingress_set="
    del(
        .metadata.uid,
        .metadata.resourceVersion,
        .metadata.creationTimestamp,
        .metadata.generation,
        .status
    )
"
 
cm_set="
    del(
        .metadata.uid,
        .metadata.annotations,
        .metadata.resourceVersion,
        .metadata.creationTimestamp
    )
"
secret_set="
    del(
        .metadata.uid,
        .metadata.annotations,
        .metadata.resourceVersion,
        .metadata.creationTimestamp
    )
"
svc_set="
    del(
        .metadata.uid,
        .metadata.resourceVersion,
        .metadata.creationTimestamp,
        .metadata.annotations,
        .status,
        .spec.clusterIP,
        .spec.clusterIPs,
        .spec.internalTrafficPolicy,
        .spec.ipFamilies,
        .spec.ipFamilyPolicy,
        .spec.sessionAffinity
    )
"
 
deploy_set="
    del(
        .metadata.uid,
        .metadata.generation,
        .metadata.resourceVersion,
        .metadata.creationTimestamp,
        .metadata.annotations,
        .status,
        .spec.progressDeadlineSeconds,
        .spec.revisionHistoryLimit,
        .spec.strategy,
        .spec.template.metadata.annotations,
        .spec.template.metadata.creationTimestamp
    )
"
statefulset_set="
    del(
        .metadata.generation,
        .metadata.uid,
        .metadata.resourceVersion,
        .metadata.creationTimestamp,
        .spec.podManagementPolicy,
        .spec.revisionHistoryLimit,
        .spec.template.metadata.creationTimestamp,
        .spec.template.metadata.annotations,
        .spec.template.spec.restartPolicy,
        .spec.template.spec.schedulerName,
        .spec.template.spec.securityContext,
        .spec.updateStrategy,
        .status
    )
"
pvc_set="
    del(

        
      
        .metadata.annotations,
        
        .spec.progressDeadlineSeconds,
        .spec.revisionHistoryLimit,
        .spec.volumeMode,
        .spec.volumeName,
        .spec.template.metadata.annotations,
        .spec.template.metadata.creationTimestamp
    )
"

 
function backup_k8s_to_yaml(){
for ns in ${NS_LIST};do
  BACKUP_DIR_DATE=${CURRENT_BACKUP_DIR}/${ns}  #备份目录，按namespace根据时间分别创建
  mkdir -p ${BACKUP_DIR_DATE} && cd ${BACKUP_DIR_DATE}  #创建备份目录
  for type in ${CONFIG_TYPE};do
    item_num=$(kubectl -n ${ns} get ${type} 2>/dev/null|wc -l)  #过滤资源类型为空
    if [ ${item_num} -lt 1 ];then continue;fi #包含NAME行，所以如果存在资源item_num不小于2
    ITEM_LIST=$(kubectl -n ${ns} get ${type} | awk '{print $1}' | grep -v 'NAME')
    for item in ${ITEM_LIST};do
       file_name=${BACKUP_DIR_DATE}/${type}_${item}.yaml
       case ${type} in
         "cm")
             set_info=${cm_set}
             ;;
         "svc")
             set_info=${svc_set}
             ;;
         "secret")
             set_info=${secret_set}
             ;;
         "ingress")
         set_info=${ingress_set}
             ;;
           #kubectl -n ${ns} get ${type} ${item} -o=json | jq '. |${ingress_set}'|yq eval -P > ${file_name};;
         "deploy")
            set_info=${deploy_set}
            ;;
         "statefulsets")
            set_info=${statefulset_set}
            ;;
         "pvc")
            set_info=${pvc_set}
            ;;
            
      esac
       kubectl -n ${ns} get ${type} ${item} -o=json | jq --args "${set_info}" '.|${set_info}'| yq eval -P > ${file_name}
       [[ $? -ne 0 ]] && exit
    done 
  done
done
}
 
 
function archive_and_upload(){
 
archive_file_name=k8s-backup-${DATA_TIME}.tar.gz
cd ${BACKUP_DIR_BASE} && tar  -jcf ${archive_file_name}  ${DATA_TIME} &> /dev/null
if [[ -s ${archive_file_name} ]];then
   /usr/bin/python3 ${CURRENT_DIR}/oss_uoload.py  k8s_backup/${archive_file_name}  ${BACKUP_DIR_BASE}/${archive_file_name}
fi
}
 
 
function main(){
  backup_k8s_to_yaml;
}
 
main;