//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployMoodNft} from "script/DeployMoodNft.s.sol";
import {MoodNft} from "src/MoodNft.sol";

contract DeployMoodNftTest is Test {
    DeployMoodNft deployer;
    string public constant HAPPY_FACE_SVG_CODE =
        unicode"<svg \
  width=\"200\" \
  height=\"200\" \
  viewBox=\"0 0 200 200\" \
  xmlns=\"http://www.w3.org/2000/svg\"> \
  <!-- Twarz --> \
  <circle cx=\"100\" cy=\"100\" r=\"90\" fill=\"#f1c40f\" /> \
  <!-- Oczy białe --> \
  <circle cx=\"65\" cy=\"80\" r=\"15\" fill=\"#fff\" /> \
  <circle cx=\"135\" cy=\"80\" r=\"15\" fill=\"#fff\" /> \
  <!-- Źrenice --> \
  <circle cx=\"65\" cy=\"80\" r=\"7\" fill=\"#2c3e50\" /> \
  <circle cx=\"135\" cy=\"80\" r=\"7\" fill=\"#2c3e50\" /> \
  <!-- Uśmiech z animacją --> \
  <path \
    fill=\"none\" \
    stroke=\"#2c3e50\" \
    stroke-width=\"6\" \
    stroke-linecap=\"round\" \
    d=\"M60 130 Q100 170 140 130\"> \
    <animate \
      attributeName=\"d\" \
      dur=\"2s\" \
      repeatCount=\"indefinite\" \
      values=\"M60 130 Q100 170 140 130;M60 128 Q100 175 140 128;M60 130 Q100 170 140 130\" /> \
  </path> \
</svg>";

    string public constant HAPPY_SVG_URI = string(
        abi.encodePacked(
            "data:image/svg+xml;base64,PHN2ZwogIHdpZHRoPSIyMDAiCiAgaGVpZ2h0PSIyMDAiCiAgdmlld0JveD0iMCAwIDIwMCAyMDAiCiAgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIgo+CiAgPCEtLSBUd2FyeiAtLT4KICA8Y2lyY2xlIGN4PSIxMDAiIGN5PSIxMDAiIHI9IjkwIiBmaWxsPSIjZjFjNDBmIiAvPgoKICA8IS0tIE9jenkgYmlhxYJlIC0tPgogIDxjaXJjbGUgY3g9IjY1IiBjeT0iODAiIHI9IjE1IiBmaWxsPSIjZmZmIiAvPgogIDxjaXJjbGUgY3g9IjEzNSIgY3k9IjgwIiByPSIxNSIgZmlsbD0iI2ZmZiIgLz4KCiAgPCEtLSDFuXJlbmljZSAtLT4KICA8Y2lyY2xlIGN4PSI2NSIgY3k9IjgwIiByPSI3IiBmaWxsPSIjMmMzZTUwIiAvPgogIDxjaXJjbGUgY3g9IjEzNSIgY3k9IjgwIiByPSI3IiBmaWxsPSIjMmMzZTUwIiAvPgoKICA8IS0tIFXFm21pZWNoIHogYW5pbWFjasSFIC0tPgogIDxwYXRoCiAgICBmYWxsPSJub25lIgogICAgc3Ryb2tlPSIjMmMzZTUwIgogICAgc3Ryb2tlLXdpZHRoPSI2IgogICAgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIgogICAgZD0iTTYwIDEzMCBRMTAwIDE3MCAxNDAgMTMwIgogID4KICAgIDxhbmltYXRlCiAgICAgIGF0dHJpYnV0ZU5hbWU9ImQiCiAgICAgIGR1cj0iMnMiCiAgICAgIHJlcGVhdENvdW50PSJpbmRlZmluaXRlIgogICAgICB2YWx1ZXM9Ik02MCAxMzAgUTEwMCAxNzAgMTQwIDEzMDtNNjAgMTI4IFExMDAgMTc1IDE0MCAxMjg7TTYwIDEzMCBRMTAwIDE3MCAxNDAgMTMwIgogICAgLz4KICA8L3BhdGg+Cjwvc3ZnPgo="
        )
    );

    string public constant SAD_SVG_URI = string(
        abi.encodePacked(
            "data:image/svg+xml;base64,",
            "PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgdmlld0JveD0iMCAwIDIwMCAyMDAiIHhtbG5z",
            "PSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CiAgPCEtLSBUd2FyeiAtLT4KICA8Y2lyY2xl",
            "IGN4PSIxMDAiIGN5PSIxMDAiIHI9IjkwIiBmaWxsPSIjMmMzZTUwIiAvPgoKICA8IS0tIE9jenkg",
            "YmlhxYJlIC0tPgogIDxjaXJjbGUgY3g9IjY1IiBjeT0iODAiIHI9IjE1IiBmaWxsPSIjZWNmMGYx",
            "IiAvPgogIDxjaXJjbGUgY3g9IjEzNSIgY3k9IjgwIiByPSIxNSIgZmlsbD0iI2VjZjBmMSIgLz4K",
            "CiAgPCEtLSDFuXJlbmljZSAtLT4KICA8Y2lyY2xlIGN4PSI2NSIgY3k9IjgwIiByPSI3IiBmaWxs",
            "PSIjMzQ0OTVlIiAvPgogIDxjaXJjbGUgY3g9IjEzNSIgY3k9IjgwIiByPSI3IiBmaWxsPSIjMzQ0",
            "OTVlIiAvPgoKICA8IS0tIMWBZXprYSBzcG9kIGxld2VnbyBva2EgLS0+CiAgPGNpcmNsZSBjeD0i",
            "NjUiIGN5PSI5NSIgcj0iMyIgZmlsbD0iIzM0OThkYiI+CiAgICA8YW5pbWF0ZSBhdHRyaWJ1dGVO",
            "YW1lPSJjeSIgdmFsdWVzPSI5NTsxMjAiIGR1cj0iMS41cyIgcmVwZWF0Q291bnQ9ImluZGVmaW5p",
            "dGUiIC8+CiAgICA8YW5pbWF0ZSBhdHRyaWJ1dGVOYW1lPSJvcGFjaXR5IiB2YWx1ZXM9IjE7MCIg",
            "ZHVyPSIxLjVzIiByZXBlYXRDb3VudD0iaW5kZWZpbml0ZSIgLz4KICA8L2NpcmNsZT4KCiAgPCEt",
            "LSBTbXV0bnkgdcWbbWllY2ggeiBhbmltYWNqxIUgLS0+CiAgPHBhdGggZmlsbD0ibm9uZSIgc3Ry",
            "b2tlPSIjZWNmMGYxIiBzdHJva2Utd2lkdGg9IjYiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIKICAg",
            "ICAgICBkPSJNNjAgMTQwIFExMDAgMTEwIDE0MCAxNDAiPgogICAgPGFuaW1hdGUgYXR0cmlidXRl",
            "TmFtZT0iZCIKICAgICAgICAgICAgIGR1cj0iMnMiCiAgICAgICAgICAgICByZXBlYXRDb3VudD0i",
            "aW5kZWZpbml0ZSIKICAgICAgICAgICAgIHZhbHVlcz0iTTYwIDE0MCBRMTAwIDExMCAxNDAgMTQw",
            "OwogICAgICAgICAgICAgICAgICAgICBNNjAgMTQyIFExMDAgMTA1IDE0MCAxNDI7CiAgICAgICAg",
            "ICAgICAgICAgICAgIE02MCAxNDAgUTEwMCAxMTAgMTQwIDE0MCIvPgogIDwvcGF0aD4KPC9zdmc+",
            "Cg=="
        )
    );

    address public USER = makeAddr("USER");
    MoodNft public moodNft;

    function setUp() external {
        deployer = new DeployMoodNft();
        moodNft = deployer.run();
    }

    // function testConvertSvgToUri() external view {
    //     assert(
    //         keccak256(abi.encodePacked(HAPPY_SVG_URI))
    //             == keccak256(abi.encodePacked(deployer.svgToImageURI(HAPPY_FACE_SVG_CODE)))
    //     );
    // }

    function testFlipTokenToSad() public {
        vm.startPrank(USER);
        moodNft.mintNft();
        moodNft.flipMood(0);
        vm.stopPrank();
        assert(keccak256(abi.encodePacked(moodNft.tokenURI(0))) == keccak256(abi.encodePacked(SAD_SVG_URI)));
    }
}
