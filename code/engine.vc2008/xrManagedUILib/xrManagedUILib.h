#pragma once
#include "../xrUICore/xrUIXmlParser.h"

using namespace System;
namespace XRay
{
	namespace xrManagedUILib
	{
		public ref class UIXMLParser
		{
		internal:
			CUIXml* NativeParserObject;

			UIXMLParser();
			virtual ~UIXMLParser();
		};
	}
}