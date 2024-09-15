//
// Created by John Brewer on 2019-06-25.
//

#ifndef DICOMREADER_JERADICOMPARSER_H
#define DICOMREADER_JERADICOMPARSER_H

#include <cstdint>
#include <vector>
#include <iostream>

using namespace std;

class JeraDicomParser {
private:
    std::vector<uint8_t> _dicomFileData;
    const int PreambleSize = 128;
    const int PrefixSize = 4;

public:
    static const uint32_t TagPixelData = 0x7fe00010;
    static const uint32_t TagWindowCenter = 0x00281050;
    static const uint32_t TagWindowWidth = 0x00281051;
    static const uint32_t TagRows = 0x00280010;
    static const uint32_t TagColumns = 0x00280011;
    static const uint32_t TagSpacingBetweenSlices = 0x00180088;
    static const uint32_t TagPixelSpacing = 0x00280030;
    static const uint32_t TagStudyDescription = 0x00081030;
    static const uint32_t TagItem = 0xfffee000;
    static const uint32_t TagItemDelimitation = 0xfffee00d;
    static const uint32_t TagSequenceDelimitation = 0xfffee0dd;

    explicit JeraDicomParser(vector<uint8_t>&& dicomFileData): _dicomFileData(std::move(dicomFileData)) {}

    vector<uint8_t> GetPixelData() {
        int pos = PosForDicomTag(TagPixelData);
        int payloadSize = PayloadSize(pos);
        int offsetToPayload = pos + OffsetToPayload(pos);
        vector<uint8_t> result(_dicomFileData.begin() + offsetToPayload,
                _dicomFileData.begin() + offsetToPayload + payloadSize);
        return result;
    }

//void WalkThroughDicomFile() {
//        int pos = PreambleSize + PrefixSize;
//        while (pos < _dicomFileData->size()) {
//            print("Pos: " + String.Format("{0:X8}", pos) +
//                                "Tag: " + String.Format("{0:X8}", GetNextTag(pos)) +
//                                ", VR: " + VrForTag(pos) +
//                                ", Payload Size: " + PayloadSize(pos));
//            if (GetNextTag(pos) != TagPixelData) {
//                pos += OffsetToNextTag(pos);
//                continue;
//            }
//
//            uint8_t[] result = new uint8_t[PayloadSize(pos)];
//            Array.Copy(_dicomFileData, OffsetToPayload(pos), result, 0, PayloadSize(pos));
//            // return result;
//        }
//        //return null;
//    }

    double GetDoubleForTag(uint32_t tagVal) {
        auto s = GetStringForTag(tagVal);
        double result = stod(s);
        return result;
    }

    string GetStringForTag(uint32_t tagVal) {
        int pos = PosForDicomTag(tagVal);
        int length = UInt16AtPos(pos + 6);
        string s(_dicomFileData.begin() + pos + 8, _dicomFileData.begin() + pos + 8 + length);
//                Encoding.UTF8.GetString(_dicomFileData, pos + 8, length);
        return s;
    }

    pair<double, double> GetDoublePairForTag(uint32_t tagVal) {
        string s = GetStringForTag(tagVal);

        size_t pos = 0;

        double result1 = stod(s, &pos);
        ++pos;
        double result2 = stod(s, &pos);
        return pair<double, double>(result1, result2);
    }

    ushort GetUShortForTag(uint32_t tagVal) {
        int pos = PosForDicomTag(tagVal);
        return UInt16AtPos(pos + 8);
    }

//    class DicomElement
//    {
//        int groupNumber;
//        int attributeNumber;
//        string valueRepresentation;
//    }

    int PosForDicomTag(uint32_t tagVal) {
        uint8_t tag[4];
        tag[0] = (uint8_t) (tagVal >> 16u);
        tag[1] = (uint8_t) (tagVal >> 24u);
        tag[2] = (uint8_t) (tagVal);
        tag[3] = (uint8_t) (tagVal >> 8u);

        for (int i = 0; i < _dicomFileData.size(); i++) {
            if (_dicomFileData[i] == tag[0] &&
                _dicomFileData[i + 1] == tag[1] &&
                _dicomFileData[i + 2] == tag[2] &&
                _dicomFileData[i + 3] == tag[3]) {
                return i;
            }
        }

        return -1;
    }

private:
    uint32_t GetNextTag(int pos) {
        auto tagVal = static_cast<uint32_t>(static_cast<uint32_t>(_dicomFileData[pos] << 16u) |
                static_cast<uint32_t>(_dicomFileData[pos + 1] << 24u) |
                static_cast<uint32_t>(_dicomFileData[pos + 2]) |
                static_cast<uint32_t>(_dicomFileData[pos + 3] << 8u));
        return tagVal;
    }

    int OffsetToNextTag(int pos) {
        int result = OffsetToPayload(pos) + PayloadSize(pos);
        return result;
    }

    string VrForTag(int pos) {
        return string(reinterpret_cast<char*>(_dicomFileData.data()) + pos + 4, 2);
    }

    int PayloadSize(int pos) {
        string vr = VrForTag(pos);
        int result;
        if (vr == "OB" ||
            vr == "OW" ||
            vr == "OF" ||
            vr == "SQ" ||
            vr == "UT" ||
            vr == "UN") {
            result = Int32AtPos(pos + 8);
            if (result == -1) {
                result = EndOfSequencePos(pos + 12, 1, 0) - pos - 12;
            }
        } else {
            result = Int16AtPos(pos + 6);
        }

        return result;
    }

    int EndOfSequencePos(int pos, int sequenceDepth, int itemDepth) {
        throw exception(); // Not implemented
    }

    int OffsetToPayload(int pos) {
        string vr = VrForTag(pos);
        int result;
        if (vr == "OB" ||
            vr == "OW" ||
            vr == "OF" ||
            vr == "SQ" ||
            vr == "UT" ||
            vr == "UN") {
            result = 12;
        } else {
            result = 8;
        }

        return result;
    }

    int Int32AtPos(int pos) {
        auto result = static_cast<int32_t>(static_cast<uint32_t>(_dicomFileData[pos])|
                static_cast<uint32_t>(_dicomFileData[pos + 1] << 8u) |
                static_cast<uint32_t>(_dicomFileData[pos + 2] << 16u) |
                static_cast<uint32_t>(_dicomFileData[pos + 3] << 24u));
        return result;
    }

    int Int16AtPos(int pos) {
        auto result = static_cast<int16_t>(static_cast<uint32_t>(_dicomFileData[pos]) |
                static_cast<uint32_t>(_dicomFileData[pos + 1] << 8u));
        return result;
    }

    ushort UInt16AtPos(int pos) {
        auto result = static_cast<ushort>(static_cast<uint32_t>(_dicomFileData[pos]) |
                static_cast<uint32_t>(_dicomFileData[pos + 1] << 8u));
        return result;
    }
};

#endif //DICOMREADER_JERADICOMPARSER_H
