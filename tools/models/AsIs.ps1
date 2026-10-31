# Mo hinh AS-IS quy trinh tuyen dung - Nhom 8 MIS3047
# Toa do tinh san de BpmnLib sinh ca XML va DI.

function N($id, $kind, $name, $x, $y, $w, $h, $proc, $lane, $extra) {
    $o = [ordered]@{ id = $id; kind = $kind; name = $name; x = $x; y = $y; w = $w; h = $h; process = $proc; lane = $lane }
    if ($extra) { foreach ($k in $extra.Keys) { $o[$k] = $extra[$k] } }
    return $o
}

function Get-ModelAsIs {
    $PB = 'Lane_PB'; $NS = 'Lane_NS'; $GD = 'Lane_GD'
    $PC = 'Process_ASIS'; $PU = 'Process_UV'

    $nodes = New-Object System.Collections.ArrayList

    # ---------- Phong ban chuyen mon ----------
    [void]$nodes.Add((N 'E_NhuCau'    'startEvent' 'Nhu cầu tuyển dụng phát sinh' 250 152 36 36 $PC $PB $null))
    [void]$nodes.Add((N 'T_LapYC'     'userTask'   'Lập yêu cầu tuyển dụng'       330 130 130 80 $PC $PB $null))
    [void]$nodes.Add((N 'T_BoSung'    'manualTask' 'Bổ sung yêu cầu tuyển dụng'   520 130 130 80 $PC $PB $null))
    [void]$nodes.Add((N 'D_KeHoach'   'dataObjectRef' 'Kế hoạch tuyển dụng'       330 240 36 50 $PC $PB $null))
    [void]$nodes.Add((N 'T_PhongVan'  'manualTask' 'Phỏng vấn ứng viên'          3140 130 130 80 $PC $PB $null))
    [void]$nodes.Add((N 'T_DanhGia'   'manualTask' 'Đánh giá kết quả phỏng vấn'  3340 130 130 80 $PC $PB $null))
    [void]$nodes.Add((N 'G_KetQua'    'exclusiveGateway' 'Kết quả phỏng vấn đạt?' 3540 145 50 50 $PC $PB $null))
    [void]$nodes.Add((N 'E_KhongDat'  'endEvent'   'Ứng viên không trúng tuyển'  3640 250 36 36 $PC $PB $null))

    # ---------- Phong Nhan su ----------
    [void]$nodes.Add((N 'T_TiepNhan'  'userTask'   'Tiếp nhận và kiểm tra yêu cầu' 710 340 130 80 $PC $NS $null))
    [void]$nodes.Add((N 'G_DayDu'     'exclusiveGateway' 'Yêu cầu đã đầy đủ?'     900 355 50 50 $PC $NS $null))
    [void]$nodes.Add((N 'T_SoanJD'    'userTask'   'Soạn bản mô tả công việc'    1000 340 130 80 $PC $NS $null))
    [void]$nodes.Add((N 'D_JD'        'dataObjectRef' 'Bản JD'                    990 455 36 50 $PC $NS $null))
    [void]$nodes.Add((N 'T_ChinhJD'   'userTask'   'Chỉnh sửa bản JD'            1280 340 130 80 $PC $NS $null))
    [void]$nodes.Add((N 'G_SS_DangTin' 'parallelGateway' ''                         1530 410 50 50 $PC $NS $null))
    [void]$nodes.Add((N 'T_DangTinNgoai' 'sendTask' 'Đăng tin kênh tuyển dụng ngoài' 1630 340 130 80 $PC $NS $null))
    [void]$nodes.Add((N 'T_DangTinNoiBo' 'sendTask' 'Đăng tin cổng thông tin nội bộ' 1630 450 130 80 $PC $NS $null))
    [void]$nodes.Add((N 'G_SJ_DangTin' 'parallelGateway' ''                         1850 410 50 50 $PC $NS $null))
    [void]$nodes.Add((N 'D_ThongBao'  'dataObjectRef' 'Thông báo tuyển dụng'     1790 545 36 50 $PC $NS $null))
    [void]$nodes.Add((N 'G_SuKien'    'eventBasedGateway' 'Chờ hồ sơ hoặc hết hạn' 1990 410 50 50 $PC $NS $null))
    [void]$nodes.Add((N 'E_HetHan'    'intermediateCatchTimer' 'Hết hạn nhận hồ sơ' 2090 357 36 36 $PC $NS @{ duration = 'P21D' }))
    [void]$nodes.Add((N 'E_NhanCV'    'intermediateCatchMessage' 'Hồ sơ ứng viên nộp' 2090 482 36 36 $PC $NS @{ message = 'Msg_HoSo' }))
    [void]$nodes.Add((N 'T_LuuCV'     'serviceTask' 'Lưu hồ sơ vào Kho CV'       2190 395 130 80 $PC $NS $null))
    [void]$nodes.Add((N 'DS_KhoCV'    'dataStoreRef' 'Kho CV'                    2183 545 50 50 $PC $NS $null))
    [void]$nodes.Add((N 'T_LuuTam'    'manualTask' 'Lưu tạm và báo lỗi kỹ thuật' 2360 540 130 80 $PC $NS $null))
    [void]$nodes.Add((N 'T_SangLoc'   'manualTask' 'Sàng lọc hồ sơ thủ công'     2390 395 130 80 $PC $NS $null))
    [void]$nodes.Add((N 'G_Dat'       'exclusiveGateway' 'Hồ sơ đạt yêu cầu?'    2590 410 50 50 $PC $NS $null))
    [void]$nodes.Add((N 'E_LoaiCV'    'endEvent'   'Hồ sơ bị loại'               2597 500 36 36 $PC $NS $null))
    [void]$nodes.Add((N 'E_ChoXuLyLai' 'endEvent'   'Hồ sơ chờ xử lý lại'         2700 562 36 36 $PC $NS $null))
    [void]$nodes.Add((N 'T_LapLich'   'userTask'   'Lập lịch phỏng vấn'          2700 395 130 80 $PC $NS $null))
    [void]$nodes.Add((N 'T_ThongBaoPV' 'sendTask'   'Thông báo lịch phỏng vấn'    2900 395 130 80 $PC $NS $null))
    [void]$nodes.Add((N 'T_GuiKQ'     'sendTask'   'Gửi kết quả cho ứng viên'    3840 395 130 80 $PC $NS $null))
    [void]$nodes.Add((N 'E_XacNhan'   'intermediateCatchMessage' 'Nhận xác nhận của ứng viên' 4040 417 36 36 $PC $NS @{ message = 'Msg_XacNhan' }))
    [void]$nodes.Add((N 'T_LapQD'     'userTask'   'Lập quyết định tuyển dụng'   4140 395 130 80 $PC $NS $null))
    [void]$nodes.Add((N 'DS_QuyetDinh' 'dataStoreRef' 'Quyết định tuyển dụng'    4140 545 50 50 $PC $NS $null))
    [void]$nodes.Add((N 'T_TiepNhanNS' 'userTask'   'Tiếp nhận nhân sự'           4340 395 130 80 $PC $NS $null))
    [void]$nodes.Add((N 'DS_HoSoNS'   'dataStoreRef' 'Hồ sơ nhân sự'             4340 545 50 50 $PC $NS $null))
    [void]$nodes.Add((N 'E_KetThuc'   'endEvent'   'Hoàn tất tuyển dụng'         4540 417 36 36 $PC $NS $null))

    # ---------- Giam doc ----------
    [void]$nodes.Add((N 'T_DuyetJD'   'manualTask' 'Xem xét và phê duyệt JD'     1180 720 130 80 $PC $GD $null))
    [void]$nodes.Add((N 'G_DuyetJD'   'exclusiveGateway' 'JD được duyệt?'         1400 735 50 50 $PC $GD $null))
    [void]$nodes.Add((N 'T_NhacGD'    'sendTask'   'Gửi nhắc nhở Giám đốc'       1000 720 130 80 $PC $GD $null))
    [void]$nodes.Add((N 'E_NhacXong'  'endEvent'   'Đã nhắc, chờ duyệt tiếp'      860 782 36 36 $PC $GD $null))
    [void]$nodes.Add((N 'T_PheDuyet'  'userTask'   'Phê duyệt nhân sự'           3620 720 130 80 $PC $GD $null))

    # ---------- Su kien bien ----------
    [void]$nodes.Add((N 'B_NhacDuyet' 'boundaryTimerNI' 'Quá hạn duyệt 3 ngày'  1212 782 36 36 $PC $GD @{ attach = 'T_DuyetJD'; duration = 'P3D' }))
    [void]$nodes.Add((N 'B_LoiLuuCV'  'boundaryError'   'Lỗi lưu trữ hồ sơ'     2270 457 36 36 $PC $NS @{ attach = 'T_LuuCV'; error = 'Err_LuuCV' }))

    # ---------- Event sub-process: huy yeu cau ----------
    [void]$nodes.Add((N 'ESP_HuyYC'   'subProcess' 'Huỷ yêu cầu tuyển dụng'     2800 530 520 150 $PC $NS $null))
    [void]$nodes.Add((N 'ESP_Start'   'startMessage' 'Yêu cầu bị huỷ'           2850 596 36 36 $PC $null @{ parent = 'ESP_HuyYC'; message = 'Msg_HuyYC' }))
    [void]$nodes.Add((N 'ESP_ThongBao' 'sendTask'  'Thông báo huỷ cho các bên'   2950 574 130 80 $PC $null @{ parent = 'ESP_HuyYC' }))
    [void]$nodes.Add((N 'ESP_End'     'endEvent'  'Đã huỷ yêu cầu'             3150 596 36 36 $PC $null @{ parent = 'ESP_HuyYC' }))

    # ---------- Ung vien ----------
    [void]$nodes.Add((N 'UV_Start'    'startEvent' 'Biết tin tuyển dụng'        1650 937 36 36 $PU $null $null))
    [void]$nodes.Add((N 'UV_ChuanBiCV' 'manualTask' 'Chuẩn bị hồ sơ'             1750 915 130 80 $PU $null $null))
    [void]$nodes.Add((N 'UV_NopCV'    'userTask'   'Nộp hồ sơ'                  2000 915 130 80 $PU $null $null))
    [void]$nodes.Add((N 'UV_NhanLich' 'intermediateCatchMessage' 'Nhận lịch phỏng vấn' 2900 937 36 36 $PU $null @{ message = 'Msg_LichPV' }))
    [void]$nodes.Add((N 'UV_ThamGia'  'userTask'   'Tham gia phỏng vấn'         3140 915 130 80 $PU $null $null))
    [void]$nodes.Add((N 'UV_NhanKQ'   'intermediateCatchMessage' 'Nhận kết quả' 3840 937 36 36 $PU $null @{ message = 'Msg_KetQua' }))
    [void]$nodes.Add((N 'UV_XacNhan'  'userTask'   'Xác nhận nhận việc'         4020 915 130 80 $PU $null $null))
    [void]$nodes.Add((N 'UV_End'      'endEvent'   'Hoàn tất ứng tuyển'         4190 937 36 36 $PU $null $null))

    # ---------- Luong ----------
    $flows = New-Object System.Collections.ArrayList
    function F($id, $from, $to, $name, $points) {
        $o = [ordered]@{ id = $id; from = $from; to = $to; process = 'Process_ASIS' }
        if ($name) { $o['name'] = $name }
        if ($points) { $o['points'] = $points }
        return $o
    }

    [void]$flows.Add((F 'F01' 'E_NhuCau' 'T_LapYC' $null $null))
    [void]$flows.Add((F 'F02' 'T_LapYC' 'T_TiepNhan' $null @(@(395,210), @(395,300), @(775,300), @(775,340))))
    [void]$flows.Add((F 'F03' 'T_TiepNhan' 'G_DayDu' $null $null))
    [void]$flows.Add((F 'F04' 'G_DayDu' 'T_SoanJD' 'Đầy đủ' $null))
    [void]$flows.Add((F 'F05' 'G_DayDu' 'T_BoSung' 'Thiếu thông tin' @(@(925,355), @(925,170), @(650,170))))
    [void]$flows.Add((F 'F06' 'T_BoSung' 'T_TiepNhan' 'Gửi lại' @(@(585,210), @(585,380), @(710,380))))
    [void]$flows.Add((F 'F07' 'T_SoanJD' 'T_DuyetJD' $null @(@(1130,380), @(1155,380), @(1155,760), @(1180,760))))
    [void]$flows.Add((F 'F08' 'T_DuyetJD' 'G_DuyetJD' $null $null))
    [void]$flows.Add((F 'F09' 'G_DuyetJD' 'T_ChinhJD' 'Không duyệt' @(@(1450,760), @(1470,760), @(1470,380), @(1410,380))))
    [void]$flows.Add((F 'F10' 'T_ChinhJD' 'T_DuyetJD' 'Gửi lại' @(@(1280,380), @(1245,380), @(1245,720))))
    [void]$flows.Add((F 'F11' 'G_DuyetJD' 'G_SS_DangTin' 'Duyệt' @(@(1450,760), @(1490,760), @(1490,435), @(1530,435))))
    [void]$flows.Add((F 'F12' 'G_SS_DangTin' 'T_DangTinNgoai' $null $null))
    [void]$flows.Add((F 'F13' 'G_SS_DangTin' 'T_DangTinNoiBo' $null $null))
    [void]$flows.Add((F 'F14' 'T_DangTinNgoai' 'G_SJ_DangTin' $null $null))
    [void]$flows.Add((F 'F15' 'T_DangTinNoiBo' 'G_SJ_DangTin' $null $null))
    [void]$flows.Add((F 'F16' 'G_SJ_DangTin' 'G_SuKien' $null $null))
    [void]$flows.Add((F 'F17' 'G_SuKien' 'E_HetHan' $null @(@(2015,410), @(2015,375), @(2090,375))))
    [void]$flows.Add((F 'F18' 'G_SuKien' 'E_NhanCV' $null @(@(2015,460), @(2015,500), @(2090,500))))
    [void]$flows.Add((F 'F19' 'E_HetHan' 'T_LuuCV' $null @(@(2126,375), @(2160,375), @(2160,435), @(2190,435))))
    [void]$flows.Add((F 'F20' 'E_NhanCV' 'T_LuuCV' $null @(@(2126,500), @(2160,500), @(2160,435), @(2190,435))))
    [void]$flows.Add((F 'F21' 'T_LuuCV' 'T_SangLoc' $null $null))
    [void]$flows.Add((F 'F22' 'T_SangLoc' 'G_Dat' $null $null))
    [void]$flows.Add((F 'F23' 'G_Dat' 'E_LoaiCV' 'Không đạt' @(@(2615,460), @(2615,500))))
    [void]$flows.Add((F 'F24' 'G_Dat' 'T_LapLich' 'Đạt' $null))
    [void]$flows.Add((F 'F25' 'T_LapLich' 'T_ThongBaoPV' $null $null))
    [void]$flows.Add((F 'F26' 'T_ThongBaoPV' 'T_PhongVan' $null @(@(3030,435), @(3090,435), @(3090,170), @(3140,170))))
    [void]$flows.Add((F 'F27' 'T_PhongVan' 'T_DanhGia' $null $null))
    [void]$flows.Add((F 'F28' 'T_DanhGia' 'G_KetQua' $null $null))
    [void]$flows.Add((F 'F29' 'G_KetQua' 'E_KhongDat' 'Không đạt' @(@(3565,195), @(3565,268), @(3640,268))))
    [void]$flows.Add((F 'F30' 'G_KetQua' 'T_PheDuyet' 'Đạt' @(@(3590,170), @(3685,170), @(3685,720))))
    [void]$flows.Add((F 'F31' 'T_PheDuyet' 'T_GuiKQ' $null @(@(3750,760), @(3790,760), @(3790,435), @(3840,435))))
    [void]$flows.Add((F 'F32' 'T_GuiKQ' 'E_XacNhan' $null $null))
    [void]$flows.Add((F 'F33' 'E_XacNhan' 'T_LapQD' $null $null))
    [void]$flows.Add((F 'F34' 'T_LapQD' 'T_TiepNhanNS' $null $null))
    [void]$flows.Add((F 'F35' 'T_TiepNhanNS' 'E_KetThuc' $null $null))
    [void]$flows.Add((F 'F36' 'B_NhacDuyet' 'T_NhacGD' $null @(@(1212,800), @(1065,800))))
    [void]$flows.Add((F 'F37' 'T_NhacGD' 'E_NhacXong' $null $null))
    [void]$flows.Add((F 'F38' 'B_LoiLuuCV' 'T_LuuTam' $null @(@(2288,493), @(2288,580), @(2360,580))))
    [void]$flows.Add((F 'F39' 'T_LuuTam' 'E_ChoXuLyLai' $null $null))

    # luong trong event sub-process
    [void]$flows.Add(@{ id = 'EF01'; from = 'ESP_Start';    to = 'ESP_ThongBao'; process = 'Process_ASIS'; parent = 'ESP_HuyYC' })
    [void]$flows.Add(@{ id = 'EF02'; from = 'ESP_ThongBao'; to = 'ESP_End';       process = 'Process_ASIS'; parent = 'ESP_HuyYC' })

    # luong ung vien
    foreach ($p in @(
        @('UF01', 'UV_Start', 'UV_ChuanBiCV'), @('UF02', 'UV_ChuanBiCV', 'UV_NopCV'),
        @('UF03', 'UV_NopCV', 'UV_NhanLich'), @('UF04', 'UV_NhanLich', 'UV_ThamGia'),
        @('UF05', 'UV_ThamGia', 'UV_NhanKQ'), @('UF06', 'UV_NhanKQ', 'UV_XacNhan'),
        @('UF07', 'UV_XacNhan', 'UV_End'))) {
        [void]$flows.Add(@{ id = $p[0]; from = $p[1]; to = $p[2]; process = 'Process_UV' })
    }

    $messageFlows = New-Object System.Collections.ArrayList
    [void]$messageFlows.Add(@{ id = 'MF01'; from = 'T_DangTinNgoai'; to = 'UV_Start';   name = 'Thông báo tuyển dụng' })
    [void]$messageFlows.Add(@{ id = 'MF02'; from = 'UV_NopCV';       to = 'E_NhanCV';   name = 'Hồ sơ ứng viên' })
    [void]$messageFlows.Add(@{ id = 'MF03'; from = 'T_ThongBaoPV';   to = 'UV_NhanLich'; name = 'Lịch phỏng vấn' })
    [void]$messageFlows.Add(@{ id = 'MF04'; from = 'UV_ThamGia';     to = 'T_PhongVan'; name = 'Ứng viên tham gia' })
    [void]$messageFlows.Add(@{ id = 'MF05'; from = 'T_GuiKQ';        to = 'UV_NhanKQ';  name = 'Kết quả tuyển dụng' })
    [void]$messageFlows.Add(@{ id = 'MF06'; from = 'UV_XacNhan';     to = 'E_XacNhan';  name = 'Xác nhận nhận việc' })

    $model = @{
        collaboration = 'Collaboration_ASIS'
        errors = @(@{ id = 'Err_LuuCV'; name = 'Lỗi lưu trữ hồ sơ'; code = 'STORAGE_FAIL' })
        messages = @(
            @{ id = 'Msg_HoSo';     name = 'Hồ sơ ứng viên' },
            @{ id = 'Msg_LichPV';   name = 'Lịch phỏng vấn' },
            @{ id = 'Msg_KetQua';   name = 'Kết quả tuyển dụng' },
            @{ id = 'Msg_XacNhan';  name = 'Xác nhận nhận việc' },
            @{ id = 'Msg_HuyYC';    name = 'Yêu cầu huỷ tuyển dụng' })
        pools = @(
            @{ id = 'Pool_CongTy'; name = 'Công ty'; process = 'Process_ASIS'; x = 160; y = 80; w = 4460; h = 760
               lanes = @(
                   @{ id = 'Lane_PB'; name = 'Phòng ban chuyên môn'; x = 190; y = 80;  w = 4430; h = 220 },
                   @{ id = 'Lane_NS'; name = 'Phòng Nhân sự';        x = 190; y = 300; w = 4430; h = 380 },
                   @{ id = 'Lane_GD'; name = 'Giám đốc';             x = 190; y = 680; w = 4430; h = 160 })
            },
            @{ id = 'Pool_UngVien'; name = 'Ứng viên'; process = 'Process_UV'; x = 160; y = 880; w = 4460; h = 150; lanes = @() }
        )
        processes = @(
            @{ id = 'Process_ASIS'; name = 'Quy trình tuyển dụng hiện tại'; laneSet = 'LaneSet_ASIS'
               lanes = @(
                   @{ id = 'Lane_PB'; name = 'Phòng ban chuyên môn' },
                   @{ id = 'Lane_NS'; name = 'Phòng Nhân sự' },
                   @{ id = 'Lane_GD'; name = 'Giám đốc' }) },
            @{ id = 'Process_UV'; name = 'Quy trình phía ứng viên'; laneSet = 'LaneSet_UV'; lanes = @() }
        )
        nodes = $nodes
        flows = $flows
        messageFlows = $messageFlows
    }
    return $model
}
