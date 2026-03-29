import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  useGetReceivedWavesQuery,
  useGetSentWavesQuery,
  useRespondToWaveMutation,
} from "../../store/slices/communitySlice";
import { Bounce, toast } from "react-toastify";
import {
  ArrowLeft,
  Hand,
  Inbox,
  Send,
  Check,
  X,
  Loader2,
  Clock,
  MessageCircle,
} from "lucide-react";

interface Wave {
  _id: string;
  fromUser?: {
    _id: string;
    name: string;
    imageUrls?: string[];
  };
  toUser?: {
    _id: string;
    name: string;
    imageUrls?: string[];
  };
  message?: string;
  status: "pending" | "accepted" | "declined";
  createdAt: string;
}

const Waves: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [activeTab, setActiveTab] = useState<"received" | "sent">("received");

  const { data: receivedData, isLoading: isLoadingReceived, refetch: refetchReceived } = useGetReceivedWavesQuery({});
  const { data: sentData, isLoading: isLoadingSent } = useGetSentWavesQuery({});
  const [respondToWave, { isLoading: isResponding }] = useRespondToWaveMutation();

  const receivedWaves: Wave[] = receivedData?.data || [];
  const sentWaves: Wave[] = sentData?.data || [];

  const pendingCount = receivedWaves.filter((w) => w.status === "pending").length;

  const handleRespond = async (waveId: string, accept: boolean) => {
    try {
      await respondToWave({ waveId, accept }).unwrap();
      toast.success(
        accept
          ? t("community.waves.acceptedSuccess") || "Wave accepted!"
          : t("community.waves.declinedSuccess") || "Wave declined",
        {
          position: "top-right",
          autoClose: 2000,
          theme: "dark",
          transition: Bounce,
        }
      );
      refetchReceived();
    } catch (error) {
      toast.error(t("community.waves.respondError") || "Failed to respond to wave", {
        position: "top-right",
        autoClose: 3000,
        theme: "dark",
        transition: Bounce,
      });
    }
  };

  const formatTime = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const days = Math.floor(hours / 24);

    if (days > 0) return `${days}d ago`;
    if (hours > 0) return `${hours}h ago`;
    return "Just now";
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "accepted":
        return (
          <span className="flex items-center gap-1 text-xs bg-green-100 text-green-600 px-2 py-0.5 rounded-full">
            <Check className="w-3 h-3" />
            Accepted
          </span>
        );
      case "declined":
        return (
          <span className="flex items-center gap-1 text-xs bg-red-100 text-red-600 px-2 py-0.5 rounded-full">
            <X className="w-3 h-3" />
            Declined
          </span>
        );
      default:
        return (
          <span className="flex items-center gap-1 text-xs bg-yellow-100 text-yellow-600 px-2 py-0.5 rounded-full">
            <Clock className="w-3 h-3" />
            Pending
          </span>
        );
    }
  };

  const WaveCard: React.FC<{ wave: Wave; type: "received" | "sent" }> = ({ wave, type }) => {
    const user = type === "received" ? wave.fromUser : wave.toUser;
    const isPending = wave.status === "pending";

    return (
      <div className="bg-white/60 backdrop-blur-sm rounded-xl border border-white/30 overflow-hidden">
        <div className="p-4">
          <div className="flex items-start gap-4">
            <button
              onClick={() => navigate(`/user/${user?._id}`)}
              className="flex-shrink-0"
            >
              <div className="w-14 h-14 rounded-full bg-gradient-to-br from-purple-400 to-pink-500 overflow-hidden">
                {user?.imageUrls?.[0] ? (
                  <img
                    src={user.imageUrls[0]}
                    alt={user.name}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-white text-xl font-bold">
                    {user?.name?.[0]}
                  </div>
                )}
              </div>
            </button>

            <div className="flex-1">
              <div className="flex items-center justify-between mb-1">
                <h3 className="font-semibold text-gray-800">{user?.name}</h3>
                <span className="text-xs text-gray-400">{formatTime(wave.createdAt)}</span>
              </div>

              {wave.message && (
                <p className="text-gray-600 text-sm mb-2">{wave.message}</p>
              )}

              <div className="flex items-center justify-between">
                {type === "sent" && getStatusBadge(wave.status)}

                {type === "received" && isPending && (
                  <div className="flex gap-2">
                    <button
                      onClick={() => handleRespond(wave._id, true)}
                      disabled={isResponding}
                      className="flex items-center gap-1 px-4 py-2 bg-gradient-to-r from-green-500 to-teal-500 text-white rounded-lg font-medium hover:shadow-lg transition-all disabled:opacity-50"
                    >
                      <Check className="w-4 h-4" />
                      {t("community.waves.accept") || "Accept"}
                    </button>
                    <button
                      onClick={() => handleRespond(wave._id, false)}
                      disabled={isResponding}
                      className="flex items-center gap-1 px-4 py-2 bg-gray-100 text-gray-600 rounded-lg font-medium hover:bg-gray-200 transition-colors disabled:opacity-50"
                    >
                      <X className="w-4 h-4" />
                      {t("community.waves.decline") || "Decline"}
                    </button>
                  </div>
                )}

                {type === "received" && wave.status === "accepted" && (
                  <button
                    onClick={() => navigate(`/chat`)}
                    className="flex items-center gap-1 px-4 py-2 bg-gradient-to-r from-teal-500 to-blue-500 text-white rounded-lg font-medium hover:shadow-lg transition-all"
                  >
                    <MessageCircle className="w-4 h-4" />
                    {t("community.waves.sendMessage") || "Message"}
                  </button>
                )}

                {type === "received" && wave.status === "declined" && (
                  <span className="text-sm text-gray-400">
                    {t("community.waves.youDeclined") || "You declined this wave"}
                  </span>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  };

  const isLoading = activeTab === "received" ? isLoadingReceived : isLoadingSent;
  const waves = activeTab === "received" ? receivedWaves : sentWaves;

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 via-white to-pink-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-purple-500 to-pink-500 text-white p-6 pb-8">
        <div className="flex items-center gap-4 mb-4">
          <button
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div className="flex-1">
            <h1 className="text-xl font-bold flex items-center gap-2">
              <Hand className="w-6 h-6" />
              {t("community.waves.title") || "Waves"}
            </h1>
            <p className="text-purple-100 text-sm">
              {t("community.waves.subtitle") || "Connect with others"}
            </p>
          </div>
          {pendingCount > 0 && (
            <div className="bg-white text-purple-600 font-bold rounded-full w-8 h-8 flex items-center justify-center">
              {pendingCount}
            </div>
          )}
        </div>

        {/* Tabs */}
        <div className="flex gap-2 bg-white/20 p-1 rounded-xl">
          <button
            onClick={() => setActiveTab("received")}
            className={`flex-1 flex items-center justify-center gap-2 py-2.5 rounded-lg font-medium transition-colors ${
              activeTab === "received"
                ? "bg-white text-purple-600"
                : "text-white/70 hover:text-white"
            }`}
          >
            <Inbox className="w-5 h-5" />
            {t("community.waves.received") || "Received"}
            {pendingCount > 0 && activeTab !== "received" && (
              <span className="bg-red-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
                {pendingCount}
              </span>
            )}
          </button>
          <button
            onClick={() => setActiveTab("sent")}
            className={`flex-1 flex items-center justify-center gap-2 py-2.5 rounded-lg font-medium transition-colors ${
              activeTab === "sent"
                ? "bg-white text-purple-600"
                : "text-white/70 hover:text-white"
            }`}
          >
            <Send className="w-5 h-5" />
            {t("community.waves.sent") || "Sent"}
          </button>
        </div>
      </div>

      {/* Content */}
      <div className="px-4 py-6 max-w-2xl mx-auto">
        {isLoading ? (
          <div className="flex justify-center py-12">
            <Loader2 className="w-10 h-10 text-purple-500 animate-spin" />
          </div>
        ) : waves.length === 0 ? (
          <div className="text-center py-12">
            <div className="p-4 rounded-full bg-purple-100 w-fit mx-auto mb-4">
              <Hand className="w-8 h-8 text-purple-500" />
            </div>
            <p className="text-gray-500">
              {activeTab === "received"
                ? t("community.waves.noReceivedWaves") || "No waves received yet"
                : t("community.waves.noSentWaves") || "You haven't sent any waves yet"}
            </p>
            {activeTab === "sent" && (
              <button
                onClick={() => navigate("/community")}
                className="mt-4 px-6 py-3 bg-gradient-to-r from-purple-500 to-pink-500 text-white rounded-xl font-semibold hover:shadow-lg transition-all"
              >
                {t("community.waves.findPeople") || "Find People"}
              </button>
            )}
          </div>
        ) : (
          <div className="space-y-4">
            {waves.map((wave) => (
              <WaveCard key={wave._id} wave={wave} type={activeTab} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default Waves;
