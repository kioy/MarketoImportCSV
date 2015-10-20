#!/bin/sh
MARKETO_END_POINT=https://999-YSB-904.mktorest.com
CLIENT_ID=ed5877ae-9999-4208-99f0-e9761984ee22
CLIENT_SECRET=Pd6ICb73s999988JmxjpLICMcLzyIr
CSV_FILE_PATH=data.csv
# インポート用リスト：リードデータベース＞Imported Data from API/Imported Data
MARKETO_LIST_ID=1014

JQ="jq -r"
CURL="curl -s"
SLEEP_SEC=20

## functions ##
# アクセストークン取得
update_access_token()
{
    result_token=""
    grant_info="grant_type=client_credentials&client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}"
    token_exe="${CURL} ${MARKETO_END_POINT}/identity/oauth/token -X POST -d ${grant_info}"
    echo "実行コマンド="${token_exe}
    result_token=`${token_exe}`
    echo "実行結果="${result_token}

    # アクセストークン取り出し
    access_token=`echo ${result_token} | ${JQ} '.access_token'`
    echo "取り出したアクセストークン="${access_token}
    echo "" ##空行

}


# import API実行
import_market()
{
    result=""
    result_status=""
    result_code=""
    result_message=""

    while true
    do
        # curl実行 import API
        upload_exe="${CURL} -F format=csv -F file=@${1} -F access_token=${access_token} -F listId=${MARKETO_LIST_ID} ${MARKETO_END_POINT}/bulk/v1/leads.json"
	echo "実行コマンド="${upload_exe}
	result=`${upload_exe}`
	echo "実行結果="${result}
        # 実行結果ステータス取り出し
	result_status=`echo "${result}" | ${JQ} '.success'`
	if [ "${result_status}" = "false" ] ; then
	    result_code=`echo "${result}" | ${JQ} '.errors[0].code'`
	    result_message=`echo "${result}" | ${JQ} '.errors[0].message'`
	    if [ ${result_code} = "602" ] ; then
		echo "resuts:"${result_code}
   	        # Access トークンの期限切れのため、再取得
		update_access_token
		continue
            fi
	    echo "" ##空行
	    echo "異常終了"
	    echo "code: "${result_code}
	    echo "message: "${result_message}
	    exit 1
	fi
	batch_id=`echo "${result}" | ${JQ} '.result[0].batchId'`
	break
    done
}


import_warnings_check()
{
    result_w=""
    result_status=""
    result_code=""
    result_message=""

    while true
    do
        # curl実行 import API
        warnings_exe="${CURL} -F access_token=${access_token} -F _method=GET ${MARKETO_END_POINT}/bulk/v1/leads/batch/${batch_id}/warnings.json"
	echo "実行コマンド="${warnings_exe}
	result_w=`${warnings_exe}`
	echo "実行結果="${result_w}
        # 実行結果ステータス取り出し
	result_status=`echo "${result_w}" | ${JQ} '.success'`
	if [ "${result_status}" = "false" ] ; then
	    result_code=`echo "${result_w}" | ${JQ} '.errors[0].code'`
	    result_message=`echo "${result_w}" | ${JQ} '.errors[0].message'`
	    if [ ${result_code} = "602" ] ; then
		echo "resuts:"${result_code}
   	        # Access トークンの期限切れのため、再取得
		update_access_token
		continue
            fi
	    echo "" ##空行
	    echo "異常終了"
	    echo "code: "${result_code}
	    echo "message: "${result_message}
	    exit 1
	fi
	break
    done
}

import_failed_check()
{
    result_f=""
    result_status=""
    result_code=""
    result_message=""

    while true
    do
        # curl実行 import API
        failed_exe="${CURL} -F access_token=${access_token} -F _method=GET ${MARKETO_END_POINT}/bulk/v1/leads/batch/${batch_id}/failures.json"
	echo "実行コマンド="${failed_exe}
	result_f=`${failed_exe}`
	echo "実行結果="${result_f}
        # 実行結果ステータス取り出し
	result_status=`echo "${result_f}" | ${JQ} '.success'`
	if [ "${result_status}" = "false" ] ; then
	    result_code=`echo "${result_f}" | ${JQ} '.errors[0].code'`
	    result_message=`echo "${result_f}" | ${JQ} '.errors[0].message'`
	    if [ ${result_code} = "602" ] ; then
		echo "resuts:"${result_code}
   	        # Access トークンの期限切れのため、再取得
		update_access_token
		continue
            fi
	    echo "" ##空行
	    echo "異常終了"
	    echo "code: "${result_code}
	    echo "message: "${result_message}
	    exit 1
	fi
	break
    done
}

##############
# import ステータスチェック
import_status_check()
{
    result_s=""
    result_status=""
    result_code=""
    result_message=""
    import_warnings=""
    import_failed=""

    while true
    do
        # curl実行 import status checkAPI
        status_exe="${CURL} -F access_token=${access_token} -F _method=GET ${MARKETO_END_POINT}/bulk/v1/leads/batch/${batch_id}.json"
	echo "実行コマンド="${status_exe}
	result_s=`${status_exe}`
	echo "実行結果="${result_s}

        # 実行結果ステータス取り出し
	result_status=`echo "${result_s}" | ${JQ} '.success'`
	if [ "${result_status}" = "false" ] ; then
	    result_code=`echo "${result_s}" | ${JQ} '.errors[0].code'`
	    result_message=`echo "${result_s}" | ${JQ} '.errors[0].message'`
	    if [ ${result_code} = "602" ] ; then
		echo "resuts:"${result_code}
   	        # Access トークンの期限切れのため、再取得
		update_access_token
		continue
            fi
	    echo "" ##空行
	    echo "異常終了"
	    echo "code: "${result_code}
	    echo "message: "${result_message}
	    exit 1
	fi

	import_status=`echo "${result_s}" | ${JQ} '.result[0].status'`
	if [ ${import_status} != "Complete" ]; then
	    echo "Importing...${TXT}"
	    sleep ${SLEEP_SEC}
	    # 待ちのためループに戻る
	    continue
	fi


	# インポート終了
	# 警告と失敗のチェック
	import_warnings=`echo "${result_s}" | ${JQ} '.result[0].numOfRowsWithWarning'`
	if [ ${import_warnings} -gt 0 ]; then
	    echo "" ##空行
	    echo "!!! Warings in ${TXT}"
	    import_warnings_check

	fi
	    
	import_failed=`echo "${result_s}" | ${JQ} '.result[0].numOfRowsFailed'`
	if [ ${import_failed} -gt 0 ]; then
	    echo "" ##空行
	    echo "!!! Failed in ${TXT}"
	    import_failed_check
	fi

	break
    done
}


#############
# main body

# token 取得
access_token=""
update_access_token

# ファイル数だけループ
for TXT in ${CSV_FILE_PATH}
do
  # import API実行
  batch_id=""
  echo "========" ##空行
  echo "importing ${TXT}"
  import_market ${TXT}
  echo "${TXT} is queued as batchId: ${batch_id}"
  # import 完了チェック
  import_status_check ${batch_id}
  echo "${TXT} is imported."

done

echo "全て正常終了しました"
exit 0


